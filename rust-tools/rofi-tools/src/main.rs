//! rofi-tools: Replaces rofi-tools.sh
//!
//! Rofi menu with screenshot, clipboard, emoji, etc.

use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

fn main() {
    let items = [
        "Screenshot",
        "Screen record",
        "Clipboard history",
        "Emoji/symbol picker",
        "OCR",
        "Todo",
        "Wallpaper picker",
        "Speak (TTS)",
        "Power menu",
    ];

    let selection = run_rofi(&items, "Tools");
    let selection = match selection {
        Some(s) => s,
        None => return,
    };

    let (script, args): (&str, &[&str]) = match selection.as_str() {
        "Screenshot" => ("~/.config/rofi/scripts/screenshot.sh", &[]),
        "Screen record" => ("~/.config/rofi/scripts/screenrecord.sh", &[]),
        "Clipboard history" => ("~/.config/rofi/scripts/cliphist.sh", &[]),
        "Emoji/symbol picker" => ("~/.config/rofi/scripts/emojis.sh", &[]),
        "OCR" => ("~/.config/rofi/scripts/ocr.sh", &[]),
        "Todo" => ("~/.config/rofi/scripts/todo.sh", &[]),
        "Wallpaper picker" => ("~/.config/rofi/scripts/wallpaper.sh", &[]),
        "Speak (TTS)" => ("~/.dotfiles/rust-tools/target/release/speak-tts", &[]),
        "Power menu" => ("rofi", &["-show", "power"]),
        _ => {
            eprintln!("rofi-tools: unknown selection: {}", selection);
            std::process::exit(1);
        }
    };

    // Expand ~ to $HOME
    let home = std::env::var("HOME").unwrap_or_default();
    let expanded = if script.starts_with("~/") {
        format!("{}/{}", home.trim_end_matches('/'), &script[2..])
    } else {
        script.to_string()
    };

    let cmd: &str = if expanded.ends_with(".sh") { "sh" } else { &expanded };
    let sh_args: &[&str] = if expanded.ends_with(".sh") { &[&expanded] } else { args };

    let err = Command::new(cmd)
        .args(sh_args)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .exec();

    eprintln!("rofi-tools: failed to exec: {}", err);
    std::process::exit(1);
}

fn run_rofi(items: &[&str], prompt: &str) -> Option<String> {
    let input = items.join("\n");

    let mut child = Command::new("rofi")
        .args(&["-dmenu", "-i", "-p", prompt, "-no-custom"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .unwrap_or_else(|e| {
            eprintln!("rofi-tools: failed to run rofi: {}", e);
            std::process::exit(1);
        });

    use std::io::Write;
    if let Some(mut stdin) = child.stdin.take() {
        let _ = stdin.write_all(input.as_bytes());
    }

    let output = child.wait_with_output().ok()?;
    if !output.status.success() {
        return None;
    }

    let result = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if result.is_empty() { None } else { Some(result) }
}
