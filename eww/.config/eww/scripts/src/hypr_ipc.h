#ifndef HYPR_IPC_H
#define HYPR_IPC_H

#include <stddef.h>

/* Connect to Hyprland event socket (.socket2.sock).
   Returns fd on success, -1 on error. */
int hypr_event_connect(void);

/* Read one newline-delimited event line from the event socket.
   Returns bytes read (excluding newline), 0 on EOF, -1 on error.
   Handles partial reads internally. */
int hypr_event_readline(int fd, char *buf, size_t buflen);

/* Reset buffered event-reader state before consuming a new event socket. */
void hypr_event_reset_reader(void);

/* Send a request to Hyprland (.socket.sock) and return the response.
   e.g. hypr_request("j/workspaces") for JSON output.
   Returns malloc'd string (caller frees), or NULL on error. */
char *hypr_request(const char *cmd);

#endif
