//! tts-selection: Replaces tts-selection.sh
//!
//! Reads selected text via wl-paste, pipes to kokoro-tts, plays with paplay.

use std::process::{Command, Stdio};

fn main() {
    // Get selected text
    let output = Command::new("wl-paste")
        .arg("-p")
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .unwrap_or_else(|e| {
            eprintln!("tts-selection: failed to run wl-paste: {}", e);
            std::process::exit(1);
        });

    let text = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if text.is_empty() {
        run_cmd("notify-send", &["-a", "TTS", "TTS", "No text selected"]);
        std::process::exit(1);
    }

    run_cmd("notify-send", &["-a", "TTS", "TTS", "Reading aloud..."]);

    let home = std::env::var("HOME").unwrap_or_default();
    let kokoro = format!("{}/.local/bin/kokoro-tts", home);
    let model = format!("{}/.local/share/kokoro/kokoro-v1.0.onnx", home);
    let voices = format!("{}/.local/share/kokoro/voices-v1.0.bin", home);
    let tmpfile = "/tmp/tts-selection.wav".to_string();

    // Run kokoro-tts
    let mut child = Command::new(&kokoro)
        .args(&["-", &tmpfile, "--voice", "am_michael", "--model", &model, "--voices", &voices])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .unwrap_or_else(|e| {
            eprintln!("tts-selection: failed to run kokoro-tts: {}", e);
            std::process::exit(1);
        });

    use std::io::Write;
    if let Some(mut stdin) = child.stdin.take() {
        let _ = stdin.write_all(text.as_bytes());
    }
    let _ = child.wait();

    // Play the result
    Command::new("paplay")
        .arg(&tmpfile)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .ok();
}

fn run_cmd(cmd: &str, args: &[&str]) {
    Command::new(cmd)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .ok();
}
