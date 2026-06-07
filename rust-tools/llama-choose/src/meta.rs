//! Small derivations for the preview: file size, quantisation, "x ago".

use std::path::Path;

/// Human-readable byte size, e.g. `7.4 GB`.
pub fn human_size(bytes: u64) -> String {
    const UNITS: [&str; 5] = ["B", "KB", "MB", "GB", "TB"];
    let mut v = bytes as f64;
    let mut u = 0;
    while v >= 1024.0 && u < UNITS.len() - 1 {
        v /= 1024.0;
        u += 1;
    }
    if u == 0 {
        format!("{bytes} B")
    } else {
        format!("{v:.1} {}", UNITS[u])
    }
}

/// File size on disk, or `None` if the model file is missing — a strong signal
/// the model is already half-gone and a cull candidate.
pub fn file_size(path: &Path) -> Option<u64> {
    std::fs::metadata(path).ok().map(|m| m.len())
}

/// Best-effort quantisation tag pulled from a GGUF filename.
pub fn detect_quant(path: &Path) -> String {
    let name = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_ascii_uppercase();
    // Longest / most specific tags first so we don't match a prefix.
    const TAGS: [&str; 18] = [
        "MXFP4_MOE",
        "MXFP4",
        "UD-Q4_K_XL",
        "UD-Q6_K_XL",
        "Q4_K_XL",
        "Q6_K_XL",
        "Q4_K_M",
        "Q5_K_M",
        "Q6_K_P",
        "Q6_K",
        "Q8_0",
        "Q5_K_S",
        "Q4_0",
        "Q5_0",
        "IQ4_XS",
        "BF16",
        "F16",
        "F32",
    ];
    for tag in TAGS {
        if name.contains(tag) {
            return tag.trim_start_matches("UD-").to_string();
        }
    }
    "?".to_string()
}

/// Compact relative time like `3h ago`, `2d ago`, or `never`.
pub fn relative_time(then: Option<i64>, now: i64) -> String {
    let Some(then) = then else {
        return "never".to_string();
    };
    let d = (now - then).max(0);
    match d {
        0..=59 => "just now".to_string(),
        60..=3599 => format!("{}m ago", d / 60),
        3600..=86399 => format!("{}h ago", d / 3600),
        86400..=2591999 => format!("{}d ago", d / 86400),
        _ => format!("{}w ago", d / 604800),
    }
}
