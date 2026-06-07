//! SQLite-backed usage stats. Two things matter for the cull decision:
//!   1. how often each model is launched (the counter), and
//!   2. how fast it actually runs (tokens/s scraped from server logs).
//!
//! Generation speed (`tg`) is what the user feels; prompt-eval speed (`pp`) is
//! kept too because it explains a slow first token on big-context loads.

use rusqlite::Connection;
use rusqlite::OptionalExtension;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

type Aggregate = (Option<f64>, Option<f64>, Option<f64>, u64);

pub struct BenchmarkScores {
    pub chat: Option<f64>,
    pub code: Option<f64>,
}

/// Aggregated stats for one model alias.
pub struct ModelStats {
    pub launches: u64,
    pub last_used: Option<i64>,
    pub tg_avg: Option<f64>,
    pub tg_min: Option<f64>,
    pub tg_max: Option<f64>,
    pub tg_n: u64,
    pub pp_avg: Option<f64>,
    pub pp_n: u64,
}

pub fn now() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

fn data_dir() -> PathBuf {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    PathBuf::from(home).join(".local/share/llama-choose")
}

/// Open (creating if needed) the stats database and ensure the schema exists.
pub fn open() -> Result<Connection, String> {
    let dir = data_dir();
    std::fs::create_dir_all(&dir).map_err(|e| format!("mkdir {}: {e}", dir.display()))?;
    let conn = Connection::open(dir.join("stats.db")).map_err(|e| e.to_string())?;
    conn.execute_batch(
        "CREATE TABLE IF NOT EXISTS launches (
            id    INTEGER PRIMARY KEY,
            alias TEXT NOT NULL,
            mode  TEXT NOT NULL,
            ts    INTEGER NOT NULL
         );
         CREATE TABLE IF NOT EXISTS samples (
            id        INTEGER PRIMARY KEY,
            alias     TEXT NOT NULL,
            kind      TEXT NOT NULL,            -- 'tg' (generation) or 'pp' (prompt)
            ts        INTEGER NOT NULL,
            tok_per_s REAL NOT NULL,
            n_tokens  INTEGER NOT NULL
         );
         CREATE INDEX IF NOT EXISTS idx_samples_alias ON samples(alias, kind);
         CREATE INDEX IF NOT EXISTS idx_launches_alias ON launches(alias);
         CREATE TABLE IF NOT EXISTS benchmarks (
            id     INTEGER PRIMARY KEY,
            alias  TEXT NOT NULL,
            kind   TEXT NOT NULL,
            ts     INTEGER NOT NULL,
            score  REAL NOT NULL,
            passed INTEGER NOT NULL,
            total  INTEGER NOT NULL
         );
         CREATE INDEX IF NOT EXISTS idx_benchmarks_alias ON benchmarks(alias, kind);",
    )
    .map_err(|e| e.to_string())?;
    Ok(conn)
}

/// Record one launch of `alias` in `mode`. This is the usage counter.
pub fn record_launch(conn: &Connection, alias: &str, mode: &str) -> Result<(), String> {
    conn.execute(
        "INSERT INTO launches (alias, mode, ts) VALUES (?1, ?2, ?3)",
        (alias, mode, now()),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Append one tokens/s sample scraped from server output.
pub fn insert_sample(
    conn: &Connection,
    alias: &str,
    kind: &str,
    tok_per_s: f64,
    n_tokens: i64,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO samples (alias, kind, ts, tok_per_s, n_tokens) VALUES (?1, ?2, ?3, ?4, ?5)",
        (alias, kind, now(), tok_per_s, n_tokens),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn record_benchmark(
    conn: &Connection,
    alias: &str,
    kind: &str,
    score: f64,
    passed: u64,
    total: u64,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO benchmarks (alias, kind, ts, score, passed, total)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        (alias, kind, now(), score, passed, total),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn benchmark_scores_for(conn: &Connection, alias: &str) -> BenchmarkScores {
    BenchmarkScores {
        chat: latest_benchmark(conn, alias, "chat"),
        code: latest_benchmark(conn, alias, "code"),
    }
}

fn latest_benchmark(conn: &Connection, alias: &str, kind: &str) -> Option<f64> {
    conn.query_row(
        "SELECT score FROM benchmarks
         WHERE alias = ?1 AND kind = ?2
         ORDER BY ts DESC, id DESC LIMIT 1",
        (alias, kind),
        |row| row.get(0),
    )
    .optional()
    .ok()
    .flatten()
}

/// Aggregate stats for a single alias.
pub fn stats_for(conn: &Connection, alias: &str) -> Result<ModelStats, String> {
    let (launches, last_used): (u64, Option<i64>) = conn
        .query_row(
            "SELECT COUNT(*), MAX(ts) FROM launches WHERE alias = ?1",
            [alias],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )
        .map_err(|e| e.to_string())?;

    let (tg_avg, tg_min, tg_max, tg_n) = agg(conn, alias, "tg")?;
    let (pp_avg, _, _, pp_n) = agg(conn, alias, "pp")?;

    Ok(ModelStats {
        launches,
        last_used,
        tg_avg,
        tg_min,
        tg_max,
        tg_n,
        pp_avg,
        pp_n,
    })
}

/// The most recent `limit` generation-speed samples for `alias`, oldest first,
/// for the preview sparkline.
pub fn recent_tg(conn: &Connection, alias: &str, limit: usize) -> Vec<f64> {
    let mut out: Vec<f64> = conn
        .prepare(
            "SELECT tok_per_s FROM samples
             WHERE alias = ?1 AND kind = 'tg'
             ORDER BY ts DESC, id DESC LIMIT ?2",
        )
        .and_then(|mut stmt| {
            stmt.query_map((alias, limit as i64), |r| r.get::<_, f64>(0))?
                .collect::<Result<Vec<_>, _>>()
        })
        .unwrap_or_default();
    out.reverse(); // oldest -> newest for a left-to-right sparkline
    out
}

fn agg(conn: &Connection, alias: &str, kind: &str) -> Result<Aggregate, String> {
    conn.query_row(
        "SELECT AVG(tok_per_s), MIN(tok_per_s), MAX(tok_per_s), COUNT(*)
         FROM samples WHERE alias = ?1 AND kind = ?2",
        (alias, kind),
        |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
    )
    .map_err(|e| e.to_string())
}
