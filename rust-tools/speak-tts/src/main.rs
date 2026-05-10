//! speak-tts: Replaces speak.sh
//!
//! Lists cached TTS .wav files, shows them in rofi, plays selected.
//! If no selection or new text input, opens quickshell IPC for new TTS.

use std::fs;
use std::path::Path;
use std::process::{Command, Stdio};

fn main() {
    let home = std::env::var("HOME").expect("HOME not set");
    let cache_dir = format!("{}/.cache/speak", home);
    fs::create_dir_all(&cache_dir).ok();

    // Collect cached files
    let mut entries: Vec<(String, String, String)> = Vec::new(); // (hash, text_preview, wav_path)
    if let Ok(dir) = fs::read_dir(&cache_dir) {
        let mut txt_files: Vec<_> = dir
            .filter_map(|e| e.ok())
            .filter(|e| e.path().extension().and_then(|ext| ext.to_str()) == Some("txt"))
            .collect();
        // Sort by modification time, newest first
        txt_files.sort_by(|a, b| {
            b.metadata()
                .and_then(|m| m.modified())
                .unwrap_or(std::time::SystemTime::UNIX_EPOCH)
                .cmp(
                    &a.metadata()
                        .and_then(|m| m.modified())
                        .unwrap_or(std::time::SystemTime::UNIX_EPOCH),
                )
        });

        for entry in &txt_files {
            let hash = entry
                .path()
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or("")
                .to_string();
            let wav_path = format!("{}/{}.wav", cache_dir, hash);
            if !Path::new(&wav_path).exists() {
                continue;
            }
            let text = fs::read_to_string(entry.path())
                .unwrap_or_default()
                .replace('\n', " ");
            let preview: String = text.chars().take(200).collect();
            entries.push((hash, preview, wav_path));
        }
    }

    // Build rofi input
    let displays: Vec<&str> = entries
        .iter()
        .map(|(_, preview, _)| preview.as_str())
        .collect();
    let display_input = displays.join("\n");

    // Run rofi
    let mut child = match Command::new("rofi")
        .args(["-dmenu", "-i", "-p", "speak", "-format", "i s"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            eprintln!("speak-tts: rofi error: {}", e);
            std::process::exit(1);
        }
    };

    use std::io::Write;
    {
        let stdin = child.stdin.as_mut().unwrap();
        let _ = stdin.write_all(display_input.as_bytes());
    }

    let output = match child.wait_with_output() {
        Ok(o) => o,
        Err(_) => return,
    };

    if !output.status.success() {
        return;
    }

    let selection = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if selection.is_empty() {
        return;
    }

    // Parse "idx str" format
    let parts: Vec<&str> = selection.splitn(2, ' ').collect();
    if parts.is_empty() {
        return;
    }

    let idx: usize = parts[0].parse().unwrap_or(0);

    if idx >= entries.len() {
        // User typed new text
        let text = parts.get(1).unwrap_or(&"");
        let monitor = get_focused_monitor();
        // Open quickshell IPC speak
        Command::new("quickshell")
            .args(["ipc", "call", "--", "speak", "open", text, &monitor])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .ok();
    } else {
        // Play selected
        let (hash, _, wav_path) = &entries[idx];
        Command::new("ffplay")
            .args(["-nodisp", "-autoexit", "-loglevel", "quiet", wav_path])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .ok();
        // Touch files to update mtime without truncating cached content.
        let _ = Command::new("touch")
            .args(&[
                format!("{}/{}.txt", cache_dir, hash),
                format!("{}/{}.wav", cache_dir, hash),
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
}

fn get_focused_monitor() -> String {
    let output = Command::new("hyprctl")
        .args(["-j", "monitors"])
        .output()
        .ok();
    match output {
        Some(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout);
            if let Ok(v) = serde_json::from_str::<serde_json::Value>(&stdout) {
                v.as_array()
                    .and_then(|arr| {
                        arr.iter()
                            .find(|m| m.get("focused").and_then(|f| f.as_bool()) == Some(true))
                    })
                    .and_then(|m| m.get("name").and_then(|n| n.as_str()))
                    .unwrap_or("")
                    .to_string()
            } else {
                String::new()
            }
        }
        None => String::new(),
    }
}
