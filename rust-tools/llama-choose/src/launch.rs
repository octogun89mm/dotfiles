//! Building and running the actual inference commands.
//!
//! Single-model server modes (`server`/`phone`/`shared`) are *spawned* with
//! their stderr piped through us so we can scrape `tokens per second` lines
//! into the stats DB while echoing everything to the terminal untouched.
//! The other modes (`router`/`cli`/`vllm`) need no per-model scraping, so we
//! `exec()` into them and hand the process table straight over, exactly like
//! the old bash `exec`.

use std::io::{BufRead, BufReader, Write};
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

use crate::config::Model;
use crate::db;

const UI_CONFIG_FILE: &str = "/home/juju/.config/llama.cpp/ui-config.json";

/// Resolve a llama.cpp binary: prefer the home repo build (which is not on
/// PATH; its RPATH already covers the sibling shared libs), fall back to the
/// bare name for a regular PATH lookup.
pub fn resolve_bin(name: &str) -> String {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let candidate = format!("{home}/repos/llama.cpp/build/bin/{name}");
    if std::path::Path::new(&candidate).is_file() {
        candidate
    } else {
        name.to_string()
    }
}

/// Translate INI key/values into `llama` long-option flags.
///
/// `key = value` becomes `--key value`; the boolean form `key = true`
/// becomes a bare `--key` flag (e.g. `jinja = true` -> `--jinja`).
pub fn build_load_args(model: &Model) -> Vec<String> {
    let mut args = Vec::new();
    for (k, v) in &model.kv {
        if v == "true" {
            args.push(format!("--{k}"));
        } else if v == "false" {
            // A llama.cpp boolean explicitly disabled: drop it, there is no
            // generic negative form we can rely on across options.
            continue;
        } else {
            args.push(format!("--{k}"));
            args.push(v.clone());
        }
    }
    args
}

/// `llama-server` command for a single model in a server-style mode.
pub fn build_server_command(model: &Model, host: &str, port: u16, parallel: u32) -> Vec<String> {
    let mut cmd = vec![resolve_bin("llama-server")];
    cmd.extend(build_load_args(model));
    cmd.extend([
        "--alias".into(),
        model.alias.clone(),
        "--host".into(),
        host.to_string(),
        "--port".into(),
        port.to_string(),
        "--timeout".into(),
        "600".into(),
        "--parallel".into(),
        parallel.to_string(),
        "--ui".into(),
        "--ui-mcp-proxy".into(),
        "--ui-config-file".into(),
        UI_CONFIG_FILE.into(),
    ]);
    cmd
}

/// `llama-server` router mode: serve every model in the preset file.
pub fn build_router_command(ini_path: &str, host: &str, port: u16, parallel: u32) -> Vec<String> {
    vec![
        resolve_bin("llama-server"),
        "--models-preset".into(),
        ini_path.to_string(),
        "--host".into(),
        host.to_string(),
        "--port".into(),
        port.to_string(),
        "--timeout".into(),
        "600".into(),
        "--ui".into(),
        "--ui-mcp-proxy".into(),
        "--ui-config-file".into(),
        UI_CONFIG_FILE.into(),
        "--parallel".into(),
        parallel.to_string(),
    ]
}

/// Interactive `llama-cli` for a single model. Returns (env, command).
pub fn build_cli_command(model: &Model, lib_dir: &str) -> (Vec<(String, String)>, Vec<String>) {
    let ld = match std::env::var("LD_LIBRARY_PATH") {
        Ok(existing) if !existing.is_empty() => format!("{lib_dir}:{existing}"),
        _ => lib_dir.to_string(),
    };
    let mut cmd = vec![resolve_bin("llama-cli")];
    cmd.extend(build_load_args(model));
    cmd.extend(["--conversation".into(), "--color".into(), "auto".into()]);
    (vec![("LD_LIBRARY_PATH".into(), ld)], cmd)
}

/// Shell-quote a single argument for the echoed `+ ...` command line.
fn shell_quote(s: &str) -> String {
    if !s.is_empty()
        && s.bytes()
            .all(|b| b.is_ascii_alphanumeric() || b"@%-_=+:,./".contains(&b))
    {
        s.to_string()
    } else {
        format!("'{}'", s.replace('\'', "'\\''"))
    }
}

/// Echo the command the way the old script did: `+ prog arg arg`.
pub fn echo_command(env: &[(String, String)], cmd: &[String]) {
    let mut line = String::from("+");
    for (k, v) in env {
        line.push(' ');
        line.push_str(&format!("{k}={}", shell_quote(v)));
    }
    for part in cmd {
        line.push(' ');
        line.push_str(&shell_quote(part));
    }
    eprintln!("{line}");
}

/// Replace this process with `cmd` (router / cli / vllm). Never returns on success.
pub fn exec_replace(env: &[(String, String)], cmd: &[String]) -> ! {
    echo_command(env, cmd);
    let mut c = Command::new(&cmd[0]);
    c.args(&cmd[1..]);
    for (k, v) in env {
        c.env(k, v);
    }
    let err = c.exec(); // only returns on failure
    eprintln!("llama-choose: failed to exec {}: {err}", cmd[0]);
    std::process::exit(127);
}

/// Pull the `tokens per second` value out of a llama-server timing line.
///
/// Lines look like:
///   `prompt eval time =  500.00 ms / 50 tokens ( 10.00 ms per token, 100.00 tokens per second)`
///   `       eval time = 2000.00 ms / 100 tokens ( 20.00 ms per token,  50.00 tokens per second)`
/// We return (kind, tok_per_s, n_tokens) where kind is "pp" or "tg".
fn parse_timing_line(line: &str) -> Option<(&'static str, f64, i64)> {
    if !line.contains("tokens per second") {
        return None;
    }
    let kind = if line.contains("prompt eval time") {
        "pp"
    } else if line.contains("eval time") {
        "tg"
    } else {
        return None;
    };

    // tok/s: the number immediately before "tokens per second".
    let idx = line.find("tokens per second")?;
    let before = line[..idx].trim_end();
    let tok_per_s: f64 = before
        .rsplit(|c: char| c.is_whitespace())
        .next()?
        .parse()
        .ok()?;

    // token count: the integer right before the word "tokens".
    let n_tokens = line
        .find(" tokens (")
        .and_then(|p| line[..p].trim_end().rsplit(char::is_whitespace).next())
        .and_then(|s| s.parse().ok())
        .unwrap_or(0);

    Some((kind, tok_per_s, n_tokens))
}

/// Spawn a server command, echo its stderr through to our own stderr, and
/// scrape timing lines into the stats DB under `alias`. Returns the exit code.
pub fn run_with_scrape(cmd: &[String], alias: &str) -> i32 {
    echo_command(&[], cmd);

    let mut child = match Command::new(&cmd[0])
        .args(&cmd[1..])
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            eprintln!("llama-choose: failed to start {}: {e}", cmd[0]);
            return 127;
        }
    };

    // A dedicated connection for the scrape loop; failure to open just means
    // we lose stats, never the server itself.
    let sample_conn = db::open().ok();

    let stderr = child.stderr.take().expect("piped stderr");
    let reader = BufReader::new(stderr);
    let out = std::io::stderr();
    for line in reader.lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };
        // Passthrough first so the user never notices the wrapper.
        {
            let mut h = out.lock();
            let _ = writeln!(h, "{line}");
        }
        if let (Some(conn), Some((kind, tps, n))) = (&sample_conn, parse_timing_line(&line)) {
            let _ = db::insert_sample(conn, alias, kind, tps, n);
        }
    }

    match child.wait() {
        Ok(status) => status.code().unwrap_or(0),
        Err(_) => 1,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolve_bin_falls_back_to_path_lookup_when_repo_build_is_absent() {
        // resolve_bin reads HOME; the scrape test below also rewrites HOME,
        // so just point it somewhere without a llama.cpp build.
        std::env::set_var("HOME", std::env::temp_dir());
        assert_eq!(resolve_bin("llama-server"), "llama-server");
    }

    #[test]
    fn parses_generation_line() {
        let l = "       eval time =    2000.00 ms /   100 tokens (   20.00 ms per token,    50.00 tokens per second)";
        let (kind, tps, n) = parse_timing_line(l).unwrap();
        assert_eq!(kind, "tg");
        assert_eq!(n, 100);
        assert!((tps - 50.0).abs() < 1e-6);
    }

    #[test]
    fn parses_prompt_line_with_log_prefix() {
        let l = "slot      release: prompt eval time =     500.00 ms /    50 tokens (   10.00 ms per token,   100.00 tokens per second)";
        let (kind, tps, n) = parse_timing_line(l).unwrap();
        assert_eq!(kind, "pp");
        assert_eq!(n, 50);
        assert!((tps - 100.0).abs() < 1e-6);
    }

    #[test]
    fn ignores_unrelated_lines() {
        assert!(parse_timing_line("main: server is listening on http://127.0.0.1:3002").is_none());
    }

    #[test]
    fn scrapes_fake_server_stderr_into_db() {
        // Isolate the stats DB under a throwaway HOME.
        let tmp = std::env::temp_dir().join(format!("llama-choose-test-{}", std::process::id()));
        std::env::set_var("HOME", &tmp);
        let alias = "fake-model";

        // A stand-in server: emit one generation + one prompt timing line, then exit.
        let script = "printf 'srv: starting\\n' >&2; \
            printf '       eval time =    2000.00 ms /   100 tokens (   20.00 ms per token,    50.00 tokens per second)\\n' >&2; \
            printf 'prompt eval time =     500.00 ms /    50 tokens (   10.00 ms per token,   100.00 tokens per second)\\n' >&2";
        let cmd = vec!["sh".to_string(), "-c".to_string(), script.to_string()];

        let code = run_with_scrape(&cmd, alias);
        assert_eq!(code, 0, "fake server should exit cleanly");

        let conn = db::open().expect("open stats db");
        let s = db::stats_for(&conn, alias).expect("stats");
        assert_eq!(s.tg_n, 1, "one generation sample");
        assert!((s.tg_avg.unwrap() - 50.0).abs() < 1e-6);
        assert_eq!(s.pp_n, 1, "one prompt sample");
        assert!((s.pp_avg.unwrap() - 100.0).abs() < 1e-6);

        std::fs::remove_dir_all(&tmp).ok();
    }
}
