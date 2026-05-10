//! cycle-sink: Replaces cycle-sink.sh
//!
//! Cycles through PulseAudio sinks, moves all sink-inputs, notifies.

use std::process::Command;

fn main() {
    // Get all sinks
    let sinks_output = Command::new("pactl")
        .args(["list", "short", "sinks"])
        .output()
        .unwrap_or_else(|e| {
            eprintln!("cycle-sink: pactl error: {e}");
            std::process::exit(1);
        });

    let stdout = String::from_utf8_lossy(&sinks_output.stdout);
    let sinks: Vec<&str> = stdout
        .lines()
        .filter_map(|line| line.split_whitespace().nth(1))
        .collect();

    if sinks.len() < 2 {
        return;
    }

    // Get current default sink
    let info_output = Command::new("pactl")
        .args(["info"])
        .output()
        .unwrap_or_else(|e| {
            eprintln!("cycle-sink: pactl error: {e}");
            std::process::exit(1);
        });
    let info_stdout = String::from_utf8_lossy(&info_output.stdout);
    let current_sink = info_stdout
        .lines()
        .find_map(|line| line.strip_prefix("Default Sink: "))
        .map(|s| s.trim())
        .unwrap_or("");

    // Find next sink
    let next_sink = sinks
        .iter()
        .position(|&s| s == current_sink)
        .map(|i| sinks[(i + 1) % sinks.len()])
        .unwrap_or(sinks[0]);

    // Set default sink
    Command::new("pactl")
        .args(["set-default-sink", next_sink])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .ok();

    // Move all sink-inputs
    let inputs_output = Command::new("pactl")
        .args(["list", "short", "sink-inputs"])
        .output()
        .unwrap_or_else(|e| {
            eprintln!("cycle-sink: pactl error: {e}");
            std::process::exit(1);
        });
    let inputs_stdout = String::from_utf8_lossy(&inputs_output.stdout);
    for line in inputs_stdout.lines() {
        if let Some(input_id) = line.split_whitespace().next() {
            Command::new("pactl")
                .args(["move-sink-input", input_id, next_sink])
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                .status()
                .ok();
        }
    }

    // Notify
    Command::new("notify-send")
        .args([
            "-a",
            "Audio Output",
            "-t",
            "2000",
            "Sink switched",
            next_sink,
        ])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .ok();
}
