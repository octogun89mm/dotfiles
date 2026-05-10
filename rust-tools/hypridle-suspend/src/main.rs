//! hypridle-suspend: Replaces hypridle-suspend.sh
//!
//! Usage: hypridle-suspend [status|toggle|suspend]
//!
//! Manages automatic suspend enable/disable via state file.

use std::env;
use std::fs;
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::Command;

const STATE_REL: &str = "hypridle-suspend-disabled";

#[derive(serde::Serialize)]
struct Status {
    active: bool,
    status: String,
    tooltip: String,
}

fn state_path() -> String {
    let xdg_state = env::var("XDG_STATE_HOME")
        .unwrap_or_else(|_| format!("{}/.local/state", env::var("HOME").expect("HOME not set")));
    format!("{}/{}", xdg_state, STATE_REL)
}

fn do_status() {
    let path = state_path();
    let active = !Path::new(&path).exists();

    qs_common::print_json(&Status {
        active,
        status: if active {
            "enabled".to_string()
        } else {
            "disabled".to_string()
        },
        tooltip: if active {
            "Automatic suspend: ON".to_string()
        } else {
            "Automatic suspend: OFF".to_string()
        },
    });
}

fn do_toggle() {
    let path = state_path();
    if let Some(parent) = Path::new(&path).parent() {
        fs::create_dir_all(parent).ok();
    }

    if Path::new(&path).exists() {
        fs::remove_file(&path).ok();
        run_cmd(
            "notify-send",
            &[
                "-a",
                "Hypridle",
                "-t",
                "2000",
                "Automatic suspend",
                "Enabled",
            ],
        );
    } else {
        fs::write(&path, "").ok();
        run_cmd(
            "notify-send",
            &[
                "-a",
                "Hypridle",
                "-t",
                "2000",
                "Automatic suspend",
                "Disabled",
            ],
        );
    }
}

fn do_suspend() {
    let path = state_path();
    if Path::new(&path).exists() {
        return;
    }

    // Suspend
    let err = Command::new("systemctl")
        .args(["suspend"])
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .exec();
    // If exec fails
    eprintln!("hypridle-suspend: systemctl suspend failed: {err}");
    std::process::exit(1);
}

fn run_cmd(cmd: &str, args: &[&str]) {
    Command::new(cmd)
        .args(args)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .ok();
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let cmd = args.get(1).map(|s| s.as_str()).unwrap_or("suspend");

    match cmd {
        "status" => do_status(),
        "toggle" => do_toggle(),
        _ => do_suspend(),
    }
}
