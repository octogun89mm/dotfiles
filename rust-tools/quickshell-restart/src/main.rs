//! quickshell-restart: Replaces restart.sh
//!
//! Finds quickshell PIDs by config path, kills them, waits for exit, execs launch.sh.

use std::env;
use std::fs;
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

fn main() {
    let home = env::var("HOME").expect("HOME not set");
    let config_path = format!("{}/.config/quickshell/shell.qml", home);
    let launch_script = format!("{}/.config/quickshell/scripts/launch.sh", home);

    // Find quickshell PIDs for our config
    let pids = find_quickshell_pids(&config_path);

    if !pids.is_empty() {
        // Kill them
        kill_pids(&pids);

        // Wait for them to die
        for _ in 0..50 {
            let alive: Vec<u32> = pids.iter().cloned().filter(|&pid| is_alive(pid)).collect();
            if alive.is_empty() {
                break;
            }
            thread::sleep(Duration::from_millis(100));
        }
    }

    // Exec launch script
    let err = Command::new(&launch_script)
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .exec();

    // If exec fails
    eprintln!(
        "quickshell-restart: failed to exec {}: {}",
        launch_script, err
    );
    std::process::exit(1);
}

fn find_quickshell_pids(config_path: &str) -> Vec<u32> {
    let mut pids = Vec::new();
    let quickshell_list = quickshell_list_output();

    // Read /proc for quickshell processes
    if let Ok(proc_dir) = fs::read_dir("/proc") {
        for entry in proc_dir.filter_map(|e| e.ok()) {
            let pid_str = entry.file_name().into_string().ok();
            let pid: u32 = match pid_str.and_then(|s| s.parse().ok()) {
                Some(p) => p,
                None => continue,
            };

            // Check cmdline for quickshell
            let cmdline_path = entry.path().join("cmdline");
            let cmdline = match fs::read_to_string(&cmdline_path) {
                Ok(c) => c,
                Err(_) => continue,
            };

            if !cmdline.contains("quickshell") {
                continue;
            }

            // Check if this quickshell instance has our config.
            // Parse `quickshell list` once instead of spawning it for every /proc entry.
            if let Some(stdout) = &quickshell_list {
                if list_has_pid_config(stdout, pid, config_path) {
                    pids.push(pid);
                }
            } else {
                // Fallback: just kill any quickshell with matching config path
                // Check /proc/pid/fd or env
                let environ_path = entry.path().join("environ");
                if let Ok(environ) = fs::read_to_string(&environ_path) {
                    if environ.contains(config_path) {
                        pids.push(pid);
                    }
                }
            }
        }
    }

    pids.sort();
    pids.dedup();
    pids
}

fn quickshell_list_output() -> Option<String> {
    let output = Command::new("quickshell").arg("list").output().ok()?;
    if !output.status.success() {
        return None;
    }

    Some(String::from_utf8_lossy(&output.stdout).into_owned())
}

fn list_has_pid_config(list_output: &str, pid: u32, config_path: &str) -> bool {
    let pid_text = pid.to_string();
    let mut found_pid = false;

    for line in list_output.lines() {
        if line.contains("Process ID:") {
            found_pid = line
                .split_once(':')
                .map(|(_, value)| value.trim() == pid_text)
                .unwrap_or(false);
            continue;
        }

        if found_pid && line.contains("Config path:") && line.contains(config_path) {
            return true;
        }
    }

    false
}

fn kill_pids(pids: &[u32]) {
    for &pid in pids {
        // Send SIGTERM first
        let _ = Command::new("kill")
            .args([&pid.to_string()])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
}

fn is_alive(pid: u32) -> bool {
    Path::new(&format!("/proc/{}", pid)).exists()
}
