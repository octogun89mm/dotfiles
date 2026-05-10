//! rofi-apps: Replaces rofi-apps.sh
//!
//! Rofi menu with app launcher, terminal, browser, etc.

use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

fn main() {
    let items = [
        "App launcher",
        "Terminal",
        "Dropdown terminal",
        "Ranger",
        "Neovim",
        "Emacs",
        "Firefox",
        "Brave",
        "Newsboat",
        "Music player",
    ];

    let selection = run_rofi(&items, "Apps");
    let selection = match selection {
        Some(s) => s,
        None => return,
    };

    let (cmd, args): (&str, &[&str]) = match selection.as_str() {
        "App launcher" => ("rofi", &["-show", "drun"]),
        "Terminal" => ("foot", &[]),
        "Dropdown terminal" => ("foot", &["--app-id", "foot-scratchpad", "-o", "colors-dark.alpha=0.9"]),
        "Ranger" => ("foot", &["-e", "ranger"]),
        "Neovim" => ("foot", &["--app-id", "nvim", "-e", "nvim"]),
        "Emacs" => ("emacsclient", &["-c"]),
        "Firefox" => ("firefox", &["--new-window"]),
        "Brave" => ("brave", &["--new-window"]),
        "Newsboat" => ("foot", &["--app-id", "newsboat", "-e", "newsboat"]),
        "Music player" => ("foot", &["-e", "rmpc"]),
        _ => {
            eprintln!("rofi-apps: unknown selection: {}", selection);
            std::process::exit(1);
        }
    };

    let err = Command::new(cmd)
        .args(args)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .exec();

    eprintln!("rofi-apps: failed to exec {}: {}", cmd, err);
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
            eprintln!("rofi-apps: failed to run rofi: {}", e);
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
