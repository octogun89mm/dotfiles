//! wsflash: Replaces wsflash.sh
//!
//! Dispatches a Hyprland workspace command, then flashes the resulting workspace
//! number via Quickshell IPC. Only used for keyboard shortcuts.

use std::process::Command;
use std::process::Stdio;

fn hyprctl_json(args: &[&str]) -> Result<serde_json::Value, String> {
    let output = Command::new("hyprctl")
        .args(args)
        .output()
        .map_err(|e| format!("hyprctl error: {e}"))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("hyprctl error: {stderr}"));
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout).map_err(|e| format!("JSON parse: {e}"))
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <hyprctl-dispatch-args...>", args[0]);
        std::process::exit(1);
    }

    // Get focused workspace name before
    let before = hyprctl_json(&["monitors", "-j"])
        .ok()
        .and_then(|v| {
            v.as_array().and_then(|arr| {
                arr.iter()
                    .find(|m| m.get("focused").and_then(|f| f.as_bool()) == Some(true))
                    .and_then(|m| m.get("activeWorkspace"))
                    .and_then(|ws| ws.get("name").and_then(|n| n.as_str().map(String::from)))
            })
        })
        .unwrap_or_default();

    // Dispatch
    let dispatch_args: Vec<&str> = args[1..].iter().map(|s| s.as_str()).collect();
    Command::new("hyprctl")
        .args(&["dispatch"])
        .args(&dispatch_args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .ok();

    // Get focused workspace after
    let after = match hyprctl_json(&["monitors", "-j"]) {
        Ok(v) => v.as_array().and_then(|arr| {
            arr.iter()
                .find(|m| m.get("focused").and_then(|f| f.as_bool()) == Some(true))
                .map(|m| {
                    let ws = m.get("activeWorkspace");
                    let ws_name = ws.and_then(|w| w.get("name").and_then(|n| n.as_str())).unwrap_or("");
                    let mon_name = m.get("name").and_then(|n| n.as_str()).unwrap_or("");
                    (ws_name.to_string(), mon_name.to_string())
                })
        }),
        Err(_) => None,
    };

    let (ws, monitor) = match after {
        Some(a) => a,
        None => return,
    };

    // Only flash when workspace actually changed
    if ws == before {
        return;
    }

    // Skip special workspaces
    if ws.starts_with("special:") || ws.is_empty() {
        return;
    }

    // Call quickshell IPC
    Command::new("quickshell")
        .args(&["ipc", "call", "--", "workspaceflash", "show", &ws, &monitor])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .ok();
}
