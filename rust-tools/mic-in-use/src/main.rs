//! mic-in-use: Replaces mic-in-use.sh
//!
//! Checks PulseAudio for active microphone usage.
//! Output: {"active":false,"apps":[]}

use std::process::Command;

fn pactl_json(args: &[&str]) -> Result<serde_json::Value, String> {
    let output = Command::new("pactl")
        .args(args)
        .output()
        .map_err(|e| format!("pactl error: {e}"))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(format!("pactl error: {stderr}"));
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout).map_err(|e| format!("JSON parse: {e}"))
}

#[derive(serde::Serialize)]
struct Output {
    active: bool,
    apps: Vec<String>,
}

fn main() {
    let sources = match pactl_json(&["-f", "json", "list", "sources"]) {
        Ok(v) => v.as_array().cloned().unwrap_or_default(),
        Err(_) => {
            qs_common::print_json(&Output {
                active: false,
                apps: vec![],
            });
            return;
        }
    };

    let outputs = match pactl_json(&["-f", "json", "list", "source-outputs"]) {
        Ok(v) => v.as_array().cloned().unwrap_or_default(),
        Err(_) => {
            qs_common::print_json(&Output {
                active: false,
                apps: vec![],
            });
            return;
        }
    };

    // Build source index
    let mut source_by_idx = std::collections::HashMap::new();
    for s in &sources {
        if let Some(idx) = s.get("index").and_then(|i| i.as_i64()) {
            source_by_idx.insert(idx, s.clone());
        }
    }

    let mut apps: Vec<String> = Vec::new();
    for o in &outputs {
        // Skip corked outputs
        if o.get("corked").and_then(|c| c.as_bool()).unwrap_or(false) {
            continue;
        }

        let props = o
            .get("properties")
            .and_then(|p| p.as_object())
            .cloned()
            .unwrap_or_default();
        let app_name = props
            .get("application.name")
            .or_else(|| props.get("application.process.binary"))
            .or_else(|| props.get("node.name"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_lowercase();

        let app_binary = props
            .get("application.process.binary")
            .or_else(|| props.get("node.name"))
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_lowercase();

        // Skip cava, parec, pacat
        let combined = format!("{}{}", app_name, app_binary);
        if combined.contains("cava") || combined.contains("parec") || combined.contains("pacat") {
            continue;
        }

        // Get the source this output is consuming
        let source_idx = match o.get("source").and_then(|s| s.as_i64()) {
            Some(i) => i,
            None => continue,
        };

        let source = match source_by_idx.get(&source_idx) {
            Some(s) => s,
            None => continue,
        };

        // Skip monitor sources
        let device_class = source
            .get("properties")
            .and_then(|p| p.get("device.class"))
            .and_then(|v| v.as_str())
            .unwrap_or("");
        if device_class == "monitor" {
            continue;
        }

        let source_name = source.get("name").and_then(|n| n.as_str()).unwrap_or("");
        if source_name.ends_with(".monitor") {
            continue;
        }

        let app = props
            .get("application.name")
            .or_else(|| props.get("application.process.binary"))
            .or_else(|| props.get("node.name"))
            .and_then(|v| v.as_str())
            .unwrap_or("unknown")
            .to_string();
        apps.push(app);
    }

    apps.sort();
    apps.dedup();

    qs_common::print_json(&Output {
        active: !apps.is_empty(),
        apps,
    });
}
