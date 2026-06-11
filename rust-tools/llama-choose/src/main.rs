//! llama-choose: pick and launch a local inference server, and quietly keep
//! score so you know which models are worth their disk space.
//!
//! Configured models come from `~/.local/share/llama-models.ini` (the same
//! preset file `llama-server` router mode reads), while disk-only GGUFs are
//! discovered under `~/models`. Usage counts and generation speeds are
//! scraped from the server's own logs into a SQLite store and surfaced in the
//! picker.
//!
//! Subcommands:
//!   llama-choose            interactive picker (default)
//!   llama-choose stats      print the usage/speed table and exit
//!   llama-choose stop       stop any running inference server
//!   llama-choose -h         help

mod benchmark;
mod config;
mod db;
mod launch;
mod meta;
mod tui;

use std::process::Command;

use config::Model;
use rusqlite::Connection;
use tui::ModelView;

const SERVER_PORT: u16 = 3002;
const VLLM_PORT: u16 = 8000;

/// vLLM presets are independent of the GGUF INI (different runtime, different
/// log format), so they stay hard-coded as in the original script.
const VLLM_MODELS: [(&str, &str); 3] = [
    ("qwen3-0.6b", "Tiny smoke test, Qwen3 tools, low VRAM"),
    (
        "qwen2.5-1.5b-instruct",
        "Small chat model, comfortable on 12GB",
    ),
    (
        "qwen2.5-7b-instruct-awq",
        "Quantized 7B chat model, fits 12GB sanely",
    ),
];

fn home() -> String {
    std::env::var("HOME").unwrap_or_else(|_| "/root".into())
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let code = match args.get(1).map(String::as_str) {
        None => interactive(),
        Some("stats") => cmd_stats(),
        Some("bench") => cmd_bench(args.get(2), args.get(3)),
        Some("launch") => cmd_launch(args.get(2), args.get(3)),
        Some("stop") => cmd_stop(),
        Some("-h" | "--help" | "help") => {
            print_help();
            0
        }
        Some(other) => {
            eprintln!("llama-choose: unknown argument '{other}'\n");
            print_help();
            2
        }
    };
    std::process::exit(code);
}

fn print_help() {
    println!(
        "llama-choose — pick & launch a local inference server, with usage stats\n\n\
         usage:\n  \
         llama-choose          interactive model picker (default)\n  \
         llama-choose stats    print the usage / tokens-per-second table\n  \
         llama-choose bench ALIAS|all [chat|code]\n                       run dynamic correctness benchmarks via the router\n  \
         llama-choose launch ALIAS [server|phone|shared|cli]\n                       launch one model non-interactively (default: server)\n  \
         llama-choose stop     stop the running inference server\n  \
         llama-choose -h       show this help\n\n\
         configured models are read from ~/.local/share/llama-models.ini\n\
         standalone GGUFs are discovered recursively under ~/models"
    );
}

// ---------------------------------------------------------------------------
// running-process detection
// ---------------------------------------------------------------------------

fn pgrep(args: &[&str]) -> Vec<String> {
    Command::new("pgrep")
        .args(args)
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| {
            String::from_utf8_lossy(&o.stdout)
                .lines()
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect()
        })
        .unwrap_or_default()
}

fn running_pids() -> (Vec<String>, Vec<String>) {
    (pgrep(&["-x", "llama-server"]), pgrep(&["-f", "vllm serve"]))
}

// ---------------------------------------------------------------------------
// building the preview model
// ---------------------------------------------------------------------------

fn format_ctx(n: u64) -> String {
    if n >= 1024 && n.is_multiple_of(1024) {
        format!("{}K ({n})", n / 1024)
    } else {
        n.to_string()
    }
}

fn offload_str(m: &Model) -> String {
    match (m.get("n-gpu-layers"), m.get("n-cpu-moe")) {
        (Some(g), Some(c)) => format!("GPU layers {g} · CPU-MoE {c}"),
        (Some(g), None) => format!("GPU layers {g}"),
        (None, Some(c)) => format!("CPU-MoE {c}"),
        (None, None) => "default".into(),
    }
}

fn spec_str(m: &Model) -> Option<String> {
    let ty = m.get("spec-type")?;
    let drafter = if m.get("model-draft").is_some() {
        "external drafter"
    } else {
        "embedded"
    };
    let n = m
        .get("spec-draft-n-max")
        .map(|n| format!(", n={n}"))
        .unwrap_or_default();
    Some(format!("{ty} ({drafter}{n})"))
}

fn kv_cache_str(m: &Model) -> String {
    match (m.get("cache-type-k"), m.get("cache-type-v")) {
        (Some(k), Some(v)) if k == v => k.to_string(),
        (Some(k), Some(v)) => format!("{k} / {v}"),
        (Some(k), None) => k.to_string(),
        _ => "f16 (default)".into(),
    }
}

fn zero_stats() -> db::ModelStats {
    db::ModelStats {
        launches: 0,
        last_used: None,
        tg_avg: None,
        tg_min: None,
        tg_max: None,
        tg_n: 0,
        pp_avg: None,
        pp_n: 0,
    }
}

fn build_views(models: &[Model], conn: Option<&Connection>) -> Vec<ModelView> {
    let now = db::now();
    models
        .iter()
        .map(|m| {
            let path = m.model_path();
            let path_str = path
                .as_ref()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|| "(no model path)".into());
            let size_opt = path.as_ref().and_then(|p| meta::file_size(p));
            let missing = path.is_none() || size_opt.is_none();
            let s = conn
                .and_then(|c| db::stats_for(c, &m.stats_key).ok())
                .unwrap_or_else(zero_stats);
            let spark = conn
                .map(|c| db::recent_tg(c, &m.stats_key, 32))
                .unwrap_or_default()
                .iter()
                .map(|x| x.round().max(0.0) as u64)
                .collect();
            let benchmark = conn
                .map(|c| db::benchmark_scores_for(c, &m.stats_key))
                .unwrap_or(db::BenchmarkScores {
                    chat: None,
                    code: None,
                });
            ModelView {
                alias: m.alias.clone(),
                desc: m.desc.clone(),
                configured: m.configured,
                path: path_str,
                missing,
                size: size_opt.map(meta::human_size).unwrap_or_else(|| "—".into()),
                quant: path
                    .as_ref()
                    .map(|p| meta::detect_quant(p))
                    .unwrap_or_else(|| "?".into()),
                ctx: m.ctx_size().map(format_ctx).unwrap_or_else(|| "?".into()),
                offload: offload_str(m),
                kv_cache: kv_cache_str(m),
                spec: spec_str(m),
                launches: s.launches,
                last_used: meta::relative_time(s.last_used, now),
                tg_avg: s.tg_avg,
                tg_min: s.tg_min,
                tg_max: s.tg_max,
                tg_n: s.tg_n,
                pp_avg: s.pp_avg,
                pp_n: s.pp_n,
                chat_score: benchmark.chat,
                code_score: benchmark.code,
                spark,
            }
        })
        .collect()
}

fn load_models() -> Result<Vec<Model>, String> {
    let configured = config::parse(&config::default_ini_path())?;
    config::merge_discovered(configured, &config::default_models_dir())
}

// ---------------------------------------------------------------------------
// interactive flow
// ---------------------------------------------------------------------------

/// What the TUI decided to do, executed after the terminal is restored.
enum Decision {
    Quit,
    Stop,
    Router,
    Vllm(usize),
    Launch { mode: String, index: usize },
}

fn interactive() -> i32 {
    let models = match load_models() {
        Ok(m) => m,
        Err(e) => {
            eprintln!("llama-choose: {e}");
            return 1;
        }
    };

    let (llama_pids, vllm_pids) = running_pids();
    let running = !llama_pids.is_empty() || !vllm_pids.is_empty();

    // Stats are decoration; a broken stats DB must never block the picker.
    let conn = db::open().ok();
    let views = build_views(&models, conn.as_ref());

    let mut term = ratatui::init();
    let decision = run_tui(&mut term, running, &views);
    ratatui::restore();

    let decision = match decision {
        Ok(d) => d,
        Err(e) => {
            eprintln!("llama-choose: tui error: {e}");
            return 1;
        }
    };

    match decision {
        Decision::Quit => 0,
        Decision::Stop => stop_servers(&llama_pids, &vllm_pids),
        Decision::Router => launch_router(),
        Decision::Vllm(i) => launch_vllm(i),
        Decision::Launch { mode, index } => launch_model(&models[index], &mode, conn.as_ref()),
    }
}

fn run_tui(
    term: &mut ratatui::DefaultTerminal,
    running: bool,
    views: &[ModelView],
) -> std::io::Result<Decision> {
    // If anything is already on the GPU, the only sane move is to stop it.
    if running {
        let actions = vec![(
            "stop".to_string(),
            "Stop the running inference server".to_string(),
        )];
        return Ok(
            match tui::pick_action(term, "something is running", &actions)? {
                Some(_) => Decision::Stop,
                None => Decision::Quit,
            },
        );
    }

    let actions = vec![
        (
            "server".to_string(),
            "Start llama-server (127.0.0.1:3002)".to_string(),
        ),
        (
            "router".to_string(),
            "Start llama-server router mode (all models)".to_string(),
        ),
        ("vllm".to_string(), "Start vLLM OpenAI server".to_string()),
        (
            "phone".to_string(),
            "Start llama-server on Tailscale".to_string(),
        ),
        (
            "shared".to_string(),
            "Start llama-server on Tailscale for 2 users".to_string(),
        ),
        ("cli".to_string(), "Start interactive llama-cli".to_string()),
    ];

    let Some(ai) = tui::pick_action(term, "llama-choose — action", &actions)? else {
        return Ok(Decision::Quit);
    };
    let mode = actions[ai].0.clone();

    match mode.as_str() {
        "router" => Ok(Decision::Router),
        "vllm" => {
            let items: Vec<(String, String)> = VLLM_MODELS
                .iter()
                .map(|(k, d)| (k.to_string(), d.to_string()))
                .collect();
            Ok(match tui::pick_action(term, "vLLM model", &items)? {
                Some(i) => Decision::Vllm(i),
                None => Decision::Quit,
            })
        }
        _ => {
            // server / phone / shared / cli all pick a single GGUF model.
            Ok(match tui::pick_model(term, views)? {
                Some(index) => Decision::Launch { mode, index },
                None => Decision::Quit,
            })
        }
    }
}

// ---------------------------------------------------------------------------
// launching
// ---------------------------------------------------------------------------

fn tailscale_ip() -> Option<String> {
    Command::new("tailscale")
        .args(["ip", "-4"])
        .output()
        .ok()
        .filter(|o| o.status.success())
        .and_then(|o| {
            String::from_utf8_lossy(&o.stdout)
                .lines()
                .next()
                .map(|s| s.trim().to_string())
        })
        .filter(|s| !s.is_empty())
}

/// Confirm the model file (and mmproj/MTP drafter, if any) exist before we
/// bother spawning.
fn require_files(m: &Model) -> Result<(), String> {
    for key in ["model", "model-draft", "mmproj"] {
        if let Some(p) = m.get(key) {
            if !std::path::Path::new(p).is_file() {
                return Err(format!("missing {key} file: {p}"));
            }
        }
    }
    Ok(())
}

fn launch_model(m: &Model, mode: &str, conn: Option<&Connection>) -> i32 {
    if let Err(e) = require_files(m) {
        eprintln!("llama-choose: {e}");
        return 1;
    }

    if mode == "cli" {
        let lib_dir = format!("{}/repos/llama.cpp/build/bin", home());
        let (env, cmd) = launch::build_cli_command(m, &lib_dir);
        if let Some(c) = conn {
            let _ = db::record_launch(c, &m.stats_key, mode);
        }
        launch::exec_replace(&env, &cmd); // never returns
    }

    let (host, parallel) = match mode {
        "server" => ("127.0.0.1".to_string(), 1),
        "phone" | "shared" => match tailscale_ip() {
            Some(ip) => (ip, if mode == "shared" { 2 } else { 1 }),
            None => {
                eprintln!("llama-choose: could not determine Tailscale IPv4 for {mode} mode");
                return 1;
            }
        },
        other => {
            eprintln!("llama-choose: unknown server mode '{other}'");
            return 1;
        }
    };

    let cmd = launch::build_server_command(m, &host, SERVER_PORT, parallel);
    if let Some(c) = conn {
        let _ = db::record_launch(c, &m.stats_key, mode);
    }
    launch::run_with_scrape(&cmd, &m.stats_key)
}

fn launch_router() -> i32 {
    let ini = config::default_ini_path();
    let cmd = launch::build_router_command(&ini.display().to_string(), "127.0.0.1", SERVER_PORT, 1);
    launch::exec_replace(&[], &cmd);
}

fn launch_vllm(index: usize) -> i32 {
    let (key, _) = VLLM_MODELS[index];
    let hf_home = format!("{}/models/huggingface", home());
    let _ = std::fs::create_dir_all(&hf_home);
    let vllm_bin = format!("{}/repos/vllm/.venv/bin/vllm", home());

    let mut cmd = vec![vllm_bin, "serve".into()];

    let (hf_model, served, max_len, tool_args): (&str, &str, &str, Vec<&str>) = match key {
        "qwen3-0.6b" => (
            "Qwen/Qwen3-0.6B",
            "qwen3-0.6b",
            "8192",
            vec![
                "--enable-auto-tool-choice",
                "--tool-call-parser",
                "qwen3_xml",
            ],
        ),
        "qwen2.5-1.5b-instruct" => (
            "Qwen/Qwen2.5-1.5B-Instruct",
            "qwen2.5-1.5b-instruct",
            "16384",
            vec![],
        ),
        "qwen2.5-7b-instruct-awq" => (
            "Qwen/Qwen2.5-7B-Instruct-AWQ",
            "qwen2.5-7b-instruct",
            "8192",
            vec![],
        ),
        other => {
            eprintln!("llama-choose: unknown vLLM model '{other}'");
            return 1;
        }
    };

    cmd.push(hf_model.into());
    for a in [
        "--host",
        "127.0.0.1",
        "--port",
        &VLLM_PORT.to_string(),
        "--dtype",
        "auto",
        "--gpu-memory-utilization",
        "0.80",
        "--max-num-seqs",
        "1",
        "--served-model-name",
        served,
        "--max-model-len",
        max_len,
    ] {
        cmd.push(a.to_string());
    }
    for a in tool_args {
        cmd.push(a.to_string());
    }

    launch::exec_replace(&[("HF_HOME".to_string(), hf_home)], &cmd);
}

// ---------------------------------------------------------------------------
// stop
// ---------------------------------------------------------------------------

fn stop_servers(llama_pids: &[String], vllm_pids: &[String]) -> i32 {
    let all: Vec<&String> = llama_pids.iter().chain(vllm_pids.iter()).collect();
    if all.is_empty() {
        println!("no inference server running");
        return 0;
    }
    let pids: Vec<String> = all.iter().map(|s| s.to_string()).collect();
    println!("+ kill {}", pids.join(" "));
    let status = Command::new("kill").args(&pids).status();
    match status {
        Ok(s) if s.success() => {
            println!("inference server stopped");
            0
        }
        _ => {
            eprintln!("llama-choose: failed to stop one or more processes");
            1
        }
    }
}

fn cmd_stop() -> i32 {
    let (llama_pids, vllm_pids) = running_pids();
    stop_servers(&llama_pids, &vllm_pids)
}

// ---------------------------------------------------------------------------
// non-interactive stats table (the cull dashboard)
// ---------------------------------------------------------------------------

fn cmd_stats() -> i32 {
    let models = match load_models() {
        Ok(m) => m,
        Err(e) => {
            eprintln!("llama-choose: {e}");
            return 1;
        }
    };
    let conn = match db::open() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("llama-choose: {e}");
            return 1;
        }
    };

    let mut views = build_views(&models, Some(&conn));
    // Most-used first; never-launched models sink to the bottom as cull bait.
    views.sort_by(|a, b| {
        b.launches
            .cmp(&a.launches)
            .then_with(|| a.alias.cmp(&b.alias))
    });

    println!(
        "{:<24} {:<6} {:>5}  {:<9} {:>9}  {:>5} {:>5} {:>5}  {:<8}  VERDICT",
        "MODEL", "SOURCE", "RUNS", "LAST", "GEN t/s", "n", "CHAT", "CODE", "SIZE"
    );
    println!("{}", "─".repeat(100));
    for v in &views {
        let gen = v
            .tg_avg
            .map(|x| format!("{x:.1}"))
            .unwrap_or_else(|| "—".into());
        let (verdict, _) = tui::verdict(v);
        let size = if v.missing {
            "MISSING".to_string()
        } else {
            v.size.clone()
        };
        println!(
            "{:<24} {:<6} {:>5}  {:<9} {:>9}  {:>5} {:>5} {:>5}  {:<8}  {}",
            meta::truncate(&v.alias, 24),
            if v.configured { "INI" } else { "disk" },
            v.launches,
            v.last_used,
            gen,
            v.tg_n,
            v.chat_score
                .map(|x| format!("{x:.0}"))
                .unwrap_or_else(|| "—".into()),
            v.code_score
                .map(|x| format!("{x:.0}"))
                .unwrap_or_else(|| "—".into()),
            size,
            verdict
        );
    }
    0
}

/// Launch one model by alias without the TUI, e.g. from a script or tmux.
/// Uses the exact same launch path as the picker, so stats still accrue.
fn cmd_launch(alias: Option<&String>, mode: Option<&String>) -> i32 {
    let Some(alias) = alias else {
        eprintln!("usage: llama-choose launch ALIAS [server|phone|shared|cli]");
        return 2;
    };
    let mode = mode.map(String::as_str).unwrap_or("server");
    if !matches!(mode, "server" | "phone" | "shared" | "cli") {
        eprintln!("llama-choose: launch mode must be server, phone, shared, or cli");
        return 2;
    }

    let models = match load_models() {
        Ok(m) => m,
        Err(e) => {
            eprintln!("llama-choose: {e}");
            return 1;
        }
    };
    let Some(model) = models.iter().find(|m| &m.alias == alias) else {
        eprintln!("llama-choose: unknown model alias '{alias}'");
        return 1;
    };

    let (llama_pids, vllm_pids) = running_pids();
    if !llama_pids.is_empty() || !vllm_pids.is_empty() {
        eprintln!(
            "llama-choose: an inference server is already running ('llama-choose stop' first)"
        );
        return 1;
    }

    let conn = db::open().ok();
    launch_model(model, mode, conn.as_ref())
}

fn cmd_bench(alias: Option<&String>, suite: Option<&String>) -> i32 {
    let Some(alias) = alias else {
        eprintln!("usage: llama-choose bench ALIAS|all [chat|code]");
        return 2;
    };
    let models = match load_models() {
        Ok(m) => m,
        Err(e) => {
            eprintln!("llama-choose: {e}");
            return 1;
        }
    };
    let selected: Vec<&Model> = if alias == "all" {
        models.iter().filter(|m| m.configured).collect()
    } else {
        let Some(model) = models.iter().find(|m| &m.alias == alias) else {
            eprintln!("llama-choose: unknown model alias '{alias}'");
            return 1;
        };
        if !model.configured {
            eprintln!("llama-choose: benchmark requires a configured INI alias");
            return 1;
        }
        vec![model]
    };

    let suites = match suite.map(String::as_str) {
        None => vec![benchmark::Suite::Chat, benchmark::Suite::Code],
        Some(name) => match benchmark::Suite::parse(name) {
            Some(s) => vec![s],
            None => {
                eprintln!("llama-choose: benchmark suite must be 'chat' or 'code'");
                return 2;
            }
        },
    };
    let conn = match db::open() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("llama-choose: {e}");
            return 1;
        }
    };

    for model in selected {
        for &suite in &suites {
            println!("{} {} benchmark:", model.alias, suite.kind());
            let previous = db::latest_benchmark(&conn, &model.stats_key, suite.kind());
            let result = match benchmark::run(&model.alias, suite) {
                Ok(result) => result,
                Err(e) => {
                    eprintln!("llama-choose: {e}");
                    eprintln!("start llama-server router mode before benchmarking");
                    return 1;
                }
            };
            if let Err(e) = db::record_benchmark(
                &conn,
                &model.stats_key,
                suite.kind(),
                result.score,
                result.passed,
                result.total,
            ) {
                eprintln!("llama-choose: cannot save benchmark: {e}");
                return 1;
            }
            let was = previous
                .map(|p| format!(", was {p:.0}"))
                .unwrap_or_default();
            println!(
                "  score: {:.0}/100 ({}/{}{was})",
                result.score, result.passed, result.total
            );
        }
    }
    0
}
