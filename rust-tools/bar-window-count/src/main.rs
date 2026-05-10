//! bar-window-count: Replaces bar_window_count.sh AND bar_layout.sh
//!
//! Usage: bar-window-count <monitor_name>
//!
//! Output: {"count":3,"layout":"MASTER"}
//!
//! Reads `hyprctl monitors -j` and `hyprctl workspaces -j`.

use std::env;
use std::process::Command;

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

#[derive(serde::Serialize)]
struct Output {
    count: u64,
    layout: String,
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let monitor_name = match args.get(1) {
        Some(n) => n.as_str(),
        None => {
            eprintln!("Usage: {} <monitor_name>", args[0]);
            std::process::exit(1);
        }
    };

    let monitors = match hyprctl_json(&["monitors", "-j"]) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("{e}");
            qs_common::print_json(&Output {
                count: 0,
                layout: String::new(),
            });
            return;
        }
    };

    let active_ws = monitors
        .as_array()
        .and_then(|arr| {
            arr.iter().find(|m| m.get("name").and_then(|n| n.as_str()) == Some(monitor_name))
        })
        .and_then(|m| m.get("activeWorkspace"))
        .and_then(|ws| ws.get("id"))
        .and_then(|id| id.as_i64());

    let ws_id = match active_ws {
        Some(id) => id,
        None => {
            qs_common::print_json(&Output {
                count: 0,
                layout: String::new(),
            });
            return;
        }
    };

    let workspaces = match hyprctl_json(&["workspaces", "-j"]) {
        Ok(v) => v,
        Err(_) => {
            qs_common::print_json(&Output {
                count: 0,
                layout: String::new(),
            });
            return;
        }
    };

    let result = workspaces
        .as_array()
        .and_then(|arr| {
            arr.iter().find(|ws| {
                ws.get("id")
                    .and_then(|id| id.as_i64())
                    .map(|i| i == ws_id)
                    .unwrap_or(false)
            })
        })
        .map(|ws| Output {
            count: ws.get("windows").and_then(|w| w.as_u64()).unwrap_or(0),
            layout: ws
                .get("tiledLayout")
                .and_then(|l| l.as_str())
                .unwrap_or("")
                .to_uppercase(),
        })
        .unwrap_or(Output {
            count: 0,
            layout: String::new(),
        });

    qs_common::print_json(&result);
}
