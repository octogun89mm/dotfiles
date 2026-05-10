//! model-status: Replaces model-status.sh
//!
//! Checks /proc for llama-server processes and extracts model name.
//! Output: {"loaded":true,"icon":"󰧑","tooltip":"llama.cpp loaded: gemma4"}

use std::fs;

#[derive(serde::Serialize)]
struct Output {
    loaded: bool,
    icon: String,
    tooltip: String,
}

fn main() {
    let tooltip = find_llama_server()
        .map(|name| format!("llama.cpp loaded: {}", name))
        .unwrap_or_else(|| "No llama.cpp model loaded".to_string());

    let loaded = !tooltip.starts_with("No ");

    qs_common::print_json(&Output {
        loaded,
        icon: "󰧑".to_string(),
        tooltip,
    });
}

fn find_llama_server() -> Option<String> {
    let proc = fs::read_dir("/proc").ok()?;
    for entry in proc.filter_map(|e| e.ok()) {
        let pid_str = entry.file_name().into_string().ok()?;
        let _pid: u32 = pid_str.parse().ok()?;

        let cmdline_path = entry.path().join("cmdline");
        let cmdline = fs::read_to_string(cmdline_path).ok()?;

        // Check if this is a llama-server process
        if !cmdline.contains("llama-server") {
            continue;
        }

        // Extract alias
        if let Some(pos) = cmdline.find("--alias") {
            let after = &cmdline[pos + 7..];
            let alias = after.trim_start_matches([' ', '=']);
            let end = alias.find('\0').unwrap_or(alias.len());
            let name = alias[..end].trim().to_string();
            if !name.is_empty() {
                return Some(name);
            }
        }

        // Extract model path
        if let Some(pos) = cmdline.find(" -m ") {
            let after = &cmdline[pos + 4..];
            let end = after.find('\0').unwrap_or(after.len());
            let path = &after[..end];
            if let Some(base) = path.rsplit('/').next() {
                return Some(base.to_string());
            }
        }

        // Fall back to binary name
        if let Some(pos) = cmdline.find("llama-server") {
            let after = &cmdline[pos + 12..];
            let end = after.find('\0').unwrap_or(after.len());
            return Some(after[..end].to_string());
        }
    }
    None
}
