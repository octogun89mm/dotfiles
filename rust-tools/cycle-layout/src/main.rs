//! cycle-layout: Replaces cycle-layout.sh
//!
//! Cycles through master/dwindle/scrolling/monocle for the focused workspace.

use std::process::Command;
use std::fs;

const LAYOUTS: &[&str] = &["master", "dwindle", "scrolling", "monocle"];
const REFRESH_STAMP: &str = "/tmp/quickshell-layout-refresh.state";

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
    let active = match hyprctl_json(&["activeworkspace", "-j"]) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("{}", e);
            std::process::exit(1);
        }
    };

    let ws_id = active
        .get("id")
        .and_then(|id| id.as_i64())
        .unwrap_or(1);

    let current_layout = active
        .get("tiledLayout")
        .and_then(|l| l.as_str())
        .unwrap_or("");

    // Find current index and advance
    let next_layout = LAYOUTS
        .iter()
        .position(|&l| l == current_layout)
        .map(|i| LAYOUTS[(i + 1) % LAYOUTS.len()])
        .unwrap_or("master");

    // Apply layout
    Command::new("hyprctl")
        .args(&["keyword", "workspace", &format!("{},layout:{}", ws_id, next_layout)])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .ok();

    // Touch refresh stamp
    let _ = fs::write(REFRESH_STAMP, format!("{}\n", std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)));
}
