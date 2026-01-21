#!/usr/bin/env python3
import json
import socket
import struct
import os
import sys

# Sway IPC protocol constants
MAGIC = b"i3-ipc"
# Message types
GET_TREE = 4
SUBSCRIBE = 2
# Event types (have high bit set)
EVENT_WINDOW = 0x80000003

def get_socket_path():
    """Get the Sway IPC socket path from environment."""
    return os.environ.get('SWAYSOCK') or os.environ.get('I3SOCK')

def pack_message(msg_type, payload=""):
    """Pack a message in Sway IPC format.
    
    Format: <magic-string> <payload-length> <payload-type> <payload>
    - magic-string: "i3-ipc" (6 bytes)
    - payload-length: 32-bit integer (4 bytes) - length of payload in bytes
    - payload-type: 32-bit integer (4 bytes) - the message type constant
    - payload: the actual message data (JSON string)
    """
    payload_bytes = payload.encode('utf-8')
    # struct.pack formats:
    # "=" means native byte order
    # "I" means unsigned int (4 bytes)
    header = MAGIC + struct.pack("=II", len(payload_bytes), msg_type)
    return header + payload_bytes

def unpack_message(sock):
    """Receive and unpack a message from the socket.
    
    Returns: (msg_type, payload_dict)
    Reads the header first (14 bytes), then reads the payload based on length.
    """
    # Read the header: 6 bytes magic + 4 bytes length + 4 bytes type = 14 bytes
    header = sock.recv(14)
    if len(header) < 14:
        return None, None
    
    magic = header[:6]
    if magic != MAGIC:
        return None, None
    
    # Unpack the length and type from header
    payload_len, msg_type = struct.unpack("=II", header[6:14])
    
    # Read the payload
    payload = b""
    while len(payload) < payload_len:
        chunk = sock.recv(payload_len - len(payload))
        if not chunk:
            return None, None
        payload += chunk
    
    # Parse JSON payload
    return msg_type, json.loads(payload.decode('utf-8'))

def send_message(sock, msg_type, payload=""):
    """Send a message to the socket."""
    sock.sendall(pack_message(msg_type, payload))

def get_scratchpad_windows(sock):
    """Query for current scratchpad windows.
    
    Sends GET_TREE request and parses response to find __i3_scratch workspace.
    Returns a list of dicts with 'app' and 'title' keys.
    """
    send_message(sock, GET_TREE)
    msg_type, tree = unpack_message(sock)
    
    if not tree:
        return []
    
    scratchpad_windows = []
    
    def find_scratchpad(node):
        """Recursively search the tree for the scratchpad workspace."""
        if isinstance(node, dict):
            # The scratchpad is a special workspace named __i3_scratch
            if node.get('name') == '__i3_scratch':
                # Scratchpad windows are in floating_nodes
                for window in node.get('floating_nodes', []):
                    # Get app_id (Wayland) or window_class (X11)
                    app_name = window.get('app_id') or \
                               window.get('window_properties', {}).get('class', 'unknown')
                    # Get window title (the 'name' field contains the title)
                    title = window.get('name', 'untitled')
                    scratchpad_windows.append({
                        'app': app_name,
                        'title': title
                    })
                return
            
            # Recurse through child nodes
            for child in node.get('nodes', []):
                find_scratchpad(child)
            for child in node.get('floating_nodes', []):
                find_scratchpad(child)
    
    find_scratchpad(tree)
    return scratchpad_windows

def format_output(windows):
    """Format the output: [ S [window1] [window2] ]
    
    windows: list of dicts with 'app' and 'title' keys
    """
    if not windows:
        return ""
    
    # Use just the app name for the main display
    window_parts = ' '.join(f'[{w["app"]}]' for w in windows)
    return f"[ S {window_parts} ]"

def output_waybar(text, windows):
    """Output JSON for waybar with tooltip showing class - title for each window.
    
    text: the formatted text string to display
    windows: list of dicts with 'app' and 'title' keys for tooltip
    """
    if windows:
        # Create tooltip with "app - title" for each window, one per line
        tooltip_lines = [f"{w['app']} - {w['title']}" for w in windows]
        tooltip = '\n'.join(tooltip_lines)
    else:
        tooltip = 'No windows in scratchpad'
    
    waybar_output = {
        'text': text,
        'tooltip': tooltip,
        'class': 'scratchpad' if text else 'scratchpad-empty'
    }
    print(json.dumps(waybar_output), flush=True)

def main():
    socket_path = get_socket_path()
    if not socket_path:
        print(json.dumps({'text': 'ERR', 'tooltip': 'SWAYSOCK not set'}), flush=True)
        sys.exit(1)
    
    # Connect to Sway IPC socket
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(socket_path)
    
    # Subscribe to window events
    # These fire when windows are created, closed, moved, or focused
    # The 'window' event will fire when scratchpad state changes
    subscribe_payload = json.dumps(['window'])
    send_message(sock, SUBSCRIBE, subscribe_payload)
    
    # Read the subscribe confirmation response
    unpack_message(sock)
    
    # Get initial state and output it
    windows = get_scratchpad_windows(sock)
    last_output = format_output(windows)
    output_waybar(last_output, windows)
    
    # Event loop: wait for window events and update when scratchpad changes
    while True:
        try:
            msg_type, event = unpack_message(sock)
            
            if msg_type is None:
                break
            
            # Only process window events (0x80000003)
            if msg_type == EVENT_WINDOW:
                # CRITICAL FIX: We need to use a separate socket for GET_TREE
                # because reusing the event socket can cause buffer corruption
                # when events arrive while we're waiting for the tree response
                query_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                query_sock.connect(socket_path)
                
                # Query current scratchpad state on the separate socket
                windows = get_scratchpad_windows(query_sock)
                current_output = format_output(windows)
                
                # Only output if state has changed (prevents duplicate outputs)
                # This happens because window events fire multiple times
                # (e.g., "focus" event when showing, "move" when hiding)
                if current_output != last_output:
                    output_waybar(current_output, windows)
                    last_output = current_output
                
                # Close the query socket
                query_sock.close()
                query_sock.close()
                
        except Exception as e:
            print(json.dumps({'text': 'ERR', 'tooltip': str(e)}), flush=True)
            break
    
    sock.close()

if __name__ == '__main__':
    main()
