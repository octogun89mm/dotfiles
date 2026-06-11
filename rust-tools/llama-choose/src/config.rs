//! Parse `llama-models.ini` (llama.cpp `--models-preset` format) into models.
//!
//! The file is the single source of truth shared with `llama-server` router
//! mode, so we only ever *read* it and never write keys llama.cpp wouldn't
//! understand. One concession: an optional `# desc: <text>` comment line per
//! section gives the preview pane a human label. llama.cpp's preset parser
//! treats `#`/`;` lines as comments, so router mode ignores it.

use std::collections::{BTreeMap, HashSet};
use std::path::{Path, PathBuf};

use walkdir::{DirEntry, WalkDir};

/// One `[section]` from the INI: an alias plus its ordered key/value options.
pub struct Model {
    pub alias: String,
    /// Key/value options in file order, e.g. ("n-gpu-layers", "99").
    pub kv: Vec<(String, String)>,
    /// Optional human description from a `# desc:` comment in the section.
    pub desc: Option<String>,
    /// Whether this model has a launch profile in the shared INI.
    pub configured: bool,
    /// Stable identity used for launch counters and speed samples.
    pub stats_key: String,
}

impl Model {
    pub fn get(&self, key: &str) -> Option<&str> {
        self.kv
            .iter()
            .find(|(k, _)| k == key)
            .map(|(_, v)| v.as_str())
    }

    pub fn model_path(&self) -> Option<PathBuf> {
        self.get("model").map(PathBuf::from)
    }

    pub fn ctx_size(&self) -> Option<u64> {
        self.get("ctx-size").and_then(|v| v.parse().ok())
    }
}

/// Default location of the model preset file.
pub fn default_ini_path() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    PathBuf::from(home).join(".local/share/llama-models.ini")
}

/// Default root for recursive on-disk GGUF discovery.
pub fn default_models_dir() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    PathBuf::from(home).join("models")
}

/// Strip a trailing ` #...`/` ;...` inline comment that follows whitespace.
fn strip_inline_comment(s: &str) -> &str {
    let bytes = s.as_bytes();
    for i in 1..bytes.len() {
        if (bytes[i] == b'#' || bytes[i] == b';') && bytes[i - 1].is_ascii_whitespace() {
            return s[..i].trim_end();
        }
    }
    s
}

/// Parse the INI file into models, preserving section order.
pub fn parse(path: &Path) -> Result<Vec<Model>, String> {
    let text = std::fs::read_to_string(path)
        .map_err(|e| format!("cannot read {}: {e}", path.display()))?;

    let mut models: Vec<Model> = Vec::new();

    for raw in text.lines() {
        let line = raw.trim();
        if line.is_empty() {
            continue;
        }

        // Comment line. We only care about a `desc:` marker for the current section.
        if let Some(rest) = line.strip_prefix('#').or_else(|| line.strip_prefix(';')) {
            let rest = rest.trim();
            if let Some(desc) = rest.strip_prefix("desc:") {
                if let Some(cur) = models.last_mut() {
                    cur.desc = Some(desc.trim().to_string());
                }
            }
            continue;
        }

        // Section header.
        if let Some(name) = line.strip_prefix('[').and_then(|s| s.strip_suffix(']')) {
            models.push(Model {
                alias: name.trim().to_string(),
                kv: Vec::new(),
                desc: None,
                configured: true,
                stats_key: name.trim().to_string(),
            });
            continue;
        }

        // key = value.
        if let Some((k, v)) = line.split_once('=') {
            let key = k.trim().to_string();
            let val = strip_inline_comment(v.trim()).to_string();
            if let Some(cur) = models.last_mut() {
                cur.kv.push((key, val));
            }
        }
    }

    if models.is_empty() {
        return Err(format!("no models defined in {}", path.display()));
    }
    Ok(models)
}

fn is_skipped_dir(entry: &DirEntry) -> bool {
    if entry.depth() == 0 || !entry.file_type().is_dir() {
        return false;
    }
    matches!(entry.file_name().to_str(), Some(".cache" | "huggingface"))
}

fn shard_number(name: &str) -> Option<u32> {
    let stem = name.strip_suffix(".gguf")?;
    let (before_total, total) = stem.rsplit_once("-of-")?;
    let (_, shard) = before_total.rsplit_once('-')?;
    if shard.len() != 5
        || total.len() != 5
        || !shard.bytes().all(|b| b.is_ascii_digit())
        || !total.bytes().all(|b| b.is_ascii_digit())
    {
        return None;
    }
    shard.parse().ok()
}

fn is_standalone_gguf(path: &Path) -> bool {
    let Some(name) = path.file_name().and_then(|n| n.to_str()) else {
        return false;
    };
    let lower = name.to_ascii_lowercase();
    lower.ends_with(".gguf")
        && !lower.contains("mmproj")
        && !lower.starts_with("mtp-")
        && !lower.ends_with("-mtp.gguf")
        && shard_number(&lower).is_none_or(|n| n == 1)
}

/// Recursively find standalone GGUFs, following links and deduplicating by
/// canonical path. Cache trees are excluded because they are download stores,
/// not the user's model inventory.
fn discover(root: &Path) -> Result<Vec<PathBuf>, String> {
    if !root.is_dir() {
        return Err(format!("model directory not found: {}", root.display()));
    }

    let mut found = BTreeMap::new();
    for entry in WalkDir::new(root)
        .follow_links(true)
        .into_iter()
        .filter_entry(|e| !is_skipped_dir(e))
        .filter_map(Result::ok)
    {
        let path = entry.path();
        if !entry.file_type().is_file() || !is_standalone_gguf(path) {
            continue;
        }
        if let Ok(canonical) = path.canonicalize() {
            found.entry(canonical.clone()).or_insert(canonical);
        }
    }
    Ok(found.into_values().collect())
}

fn discovered_alias(path: &Path) -> String {
    path.file_stem()
        .and_then(|n| n.to_str())
        .unwrap_or("discovered-model")
        .to_string()
}

fn discovered_model(path: PathBuf) -> Model {
    let stats_key = format!("disk:{}", path.display());
    Model {
        alias: discovered_alias(&path),
        kv: vec![
            ("model".into(), path.display().to_string()),
            ("n-gpu-layers".into(), "99".into()),
            ("ctx-size".into(), "32768".into()),
            ("jinja".into(), "true".into()),
            ("flash-attn".into(), "on".into()),
        ],
        desc: Some("Discovered on disk · unconfigured defaults".into()),
        configured: false,
        stats_key,
    }
}

/// Preserve every INI model as configured, then append disk-only GGUFs.
pub fn merge_discovered(models: Vec<Model>, root: &Path) -> Result<Vec<Model>, String> {
    let configured_paths: HashSet<PathBuf> = models
        .iter()
        .flat_map(|m| {
            ["model", "model-draft", "mmproj"]
                .into_iter()
                .filter_map(|k| m.get(k).map(PathBuf::from))
        })
        .filter_map(|p| p.canonicalize().ok())
        .collect();

    let mut merged = models;
    merged.extend(
        discover(root)?
            .into_iter()
            .filter(|path| !configured_paths.contains(path))
            .map(discovered_model),
    );
    Ok(merged)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::symlink;

    #[test]
    fn merges_disk_models_by_canonical_path_and_filters_non_standalone_files() {
        let tmp = std::env::temp_dir().join(format!(
            "llama-choose-discovery-test-{}",
            std::process::id()
        ));
        let root = tmp.join("models");
        let target = tmp.join("configured.gguf");
        std::fs::create_dir_all(&root).unwrap();
        std::fs::write(&target, b"configured").unwrap();
        symlink(&target, root.join("configured-link.gguf")).unwrap();
        std::fs::write(root.join("orphan-Q4_K_M.gguf"), b"orphan").unwrap();
        symlink(
            root.join("orphan-Q4_K_M.gguf"),
            root.join("orphan-duplicate.gguf"),
        )
        .unwrap();
        std::fs::write(root.join("mmproj-model-Q8_0.gguf"), b"projector").unwrap();
        std::fs::write(root.join("mtp-some-model.gguf"), b"drafter").unwrap();
        std::fs::write(root.join("some-model-Q4_0-MTP.gguf"), b"drafter").unwrap();
        std::fs::write(root.join("split-00001-of-00002.gguf"), b"first").unwrap();
        std::fs::write(root.join("split-00002-of-00002.gguf"), b"second").unwrap();
        std::fs::create_dir_all(root.join(".cache")).unwrap();
        std::fs::write(root.join(".cache/cached.gguf"), b"cache").unwrap();
        std::fs::create_dir_all(root.join("huggingface")).unwrap();
        std::fs::write(root.join("huggingface/download.gguf"), b"download").unwrap();

        let configured = Model {
            alias: "configured".into(),
            kv: vec![("model".into(), target.display().to_string())],
            desc: None,
            configured: true,
            stats_key: "configured".into(),
        };
        let merged = merge_discovered(vec![configured], &root).unwrap();

        assert_eq!(merged.len(), 3);
        assert!(merged[0].configured);
        assert_eq!(merged[0].stats_key, "configured");
        assert!(merged
            .iter()
            .any(|m| m.alias == "orphan-Q4_K_M" && !m.configured));
        assert_eq!(
            merged
                .iter()
                .filter(|m| !m.configured && m.alias.starts_with("orphan"))
                .count(),
            1
        );
        assert!(merged
            .iter()
            .find(|m| m.alias == "orphan-Q4_K_M")
            .unwrap()
            .stats_key
            .starts_with("disk:/"));
        assert!(merged
            .iter()
            .any(|m| m.alias == "split-00001-of-00002" && !m.configured));
        assert!(!merged.iter().any(|m| m.alias.contains("mmproj")));
        assert!(!merged
            .iter()
            .any(|m| m.alias.to_ascii_lowercase().contains("mtp")));
        assert!(!merged.iter().any(|m| m.alias.contains("00002-of")));
        assert!(!merged.iter().any(|m| m.alias == "cached"));
        assert!(!merged.iter().any(|m| m.alias == "download"));

        std::fs::remove_dir_all(&tmp).ok();
    }
}
