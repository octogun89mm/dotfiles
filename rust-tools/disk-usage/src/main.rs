//! disk-usage: Replaces disk-usage.sh
//!
//! Output: JSON array of mount info:
//! [{"mount":"/","label":"ROOT","used":"8.2","total":"31.4"}]
//!
//! Uses `statvfs` to read disk usage of root and /mnt/* mount points.

use std::ffi::CString;
use std::fs;

#[derive(serde::Serialize)]
struct Mount {
    mount: String,
    label: String,
    used: String,
    total: String,
}

fn statvfs(path: &str) -> Option<(f64, f64)> {
    // Use standard library's statvfs equivalent
    let cpath = CString::new(path).ok()?;
    let mut stat: libc::statvfs = unsafe { std::mem::zeroed() };
    let ret = unsafe { libc::statvfs(cpath.as_ptr(), &mut stat) };
    if ret != 0 {
        return None;
    }
    let block_size = stat.f_frsize as f64;
    let total_blocks = stat.f_blocks as f64;
    let free_blocks = stat.f_bfree as f64;
    let total_gb = total_blocks * block_size / 1024.0 / 1024.0 / 1024.0;
    let used_gb = (total_blocks - free_blocks) * block_size / 1024.0 / 1024.0 / 1024.0;
    Some((used_gb, total_gb))
}

fn format_gb(val: f64) -> String {
    format!("{:.1}", val)
}

fn main() {
    let mounts: Vec<String> = if let Ok(entries) = fs::read_dir("/mnt") {
        let mut m = vec!["/".to_string()];
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                m.push(path.to_string_lossy().to_string());
            }
        }
        m
    } else {
        vec!["/".to_string()]
    };

    let mut result: Vec<Mount> = Vec::new();
    let mut seen = std::collections::HashSet::new();

    for mount in &mounts {
        if !seen.insert(mount.clone()) {
            continue;
        }
        if let Some((used_gb, total_gb)) = statvfs(mount) {
            let label = if mount == "/" {
                "ROOT".to_string()
            } else {
                mount.rsplit('/').next().unwrap_or("").to_uppercase()
            };
            result.push(Mount {
                mount: mount.clone(),
                label,
                used: format_gb(used_gb),
                total: format_gb(total_gb),
            });
        }
    }

    println!("{}", serde_json::to_string(&result).unwrap());
}
