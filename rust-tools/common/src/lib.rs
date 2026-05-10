//! Shared utilities for quickshell/hyprland Rust tools.

use std::process::Command;

/// Call `hyprctl` with given args and parse JSON output.
pub fn hyprctl_json(args: &[&str]) -> Result<serde_json::Value, String> {
    let output = Command::new("hyprctl")
        .args(args)
        .output()
        .map_err(|e| format!("failed to run hyprctl: {e}"))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("hyprctl error: {stderr}"));
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout).map_err(|e| format!("hyprctl JSON parse error: {e}"))
}

/// Call `pactl` with given args and return stdout as String.
pub fn pactl_output(args: &[&str]) -> Result<String, String> {
    let output = Command::new("pactl")
        .args(args)
        .output()
        .map_err(|e| format!("failed to run pactl: {e}"))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("pactl error: {stderr}"));
    }
    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}

/// Call `pactl` with JSON output, parse into serde_json::Value.
pub fn pactl_json(args: &[&str]) -> Result<serde_json::Value, String> {
    let mut json_args = vec!["-f", "json"];
    json_args.extend_from_slice(args);
    let out = pactl_output(&json_args)?;
    serde_json::from_str(&out).map_err(|e| format!("pactl JSON parse error: {e}"))
}

/// Read a file's contents as a trimmed String.
pub fn read_state_file(path: &std::path::Path) -> Option<String> {
    std::fs::read_to_string(path)
        .ok()
        .map(|s| s.trim().to_string())
}

/// Write a String to a file, creating parent dirs.
pub fn write_state_file(path: &std::path::Path, contents: &str) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).map_err(|e| format!("mkdir error: {e}"))?;
    }
    std::fs::write(path, contents).map_err(|e| format!("write error: {e}"))
}

/// Print a JSON object and exit.
pub fn print_json(value: &impl serde::Serialize) {
    println!("{}", serde_json::to_string(value).unwrap());
}
