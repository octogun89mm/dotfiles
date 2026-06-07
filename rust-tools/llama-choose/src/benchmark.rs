//! Small repeatable correctness suites for comparing local models.
//!
//! Benchmarks call the OpenAI-compatible router already served on port 3002.
//! Each run is persisted, so the dashboard always shows the latest score
//! rather than a hard-coded guess based on model names or parameter counts.

use std::process::Command;

use serde_json::{json, Value};

const URL: &str = "http://127.0.0.1:3002/v1/chat/completions";

#[derive(Clone, Copy)]
pub enum Suite {
    Chat,
    Code,
}

impl Suite {
    pub fn kind(self) -> &'static str {
        match self {
            Self::Chat => "chat",
            Self::Code => "code",
        }
    }

    pub fn parse(s: &str) -> Option<Self> {
        match s {
            "chat" => Some(Self::Chat),
            "code" => Some(Self::Code),
            _ => None,
        }
    }
}

struct Case {
    name: &'static str,
    prompt: &'static str,
    expected: &'static str,
    match_mode: MatchMode,
}

#[derive(Clone, Copy)]
enum MatchMode {
    Exact,
    Contains,
}

const CHAT_CASES: [Case; 5] = [
    Case {
        name: "exact instruction",
        prompt: "Reply with exactly cobalt-17 and nothing else.",
        expected: "cobalt-17",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "arithmetic",
        prompt: "A crate has 6 rows of 8 jars. Ten jars are removed. Reply with only the number remaining.",
        expected: "38",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "logic",
        prompt: "Every wug is blue. No blue thing is red. Can any wug be red? Reply with only yes or no.",
        expected: "no",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "ordered extraction",
        prompt: "From `alpha:7 beta:2 gamma:9 delta:4`, return only the keys whose values are even, in source order, joined by a pipe.",
        expected: "beta|delta",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "calendar reasoning",
        prompt: "If today is Monday, what day is 9 days later? Reply with only the weekday.",
        expected: "wednesday",
        match_mode: MatchMode::Exact,
    },
];

const CODE_CASES: [Case; 5] = [
    Case {
        name: "python trace",
        prompt: "What does this Python print? Reply with only the output.\n\nx = [1, 2, 3]\nprint(sum(v * 2 for v in x))",
        expected: "12",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "rust expression",
        prompt: "Complete the Rust function with one expression. Reply with only the missing expression.\n\nfn double(x: i32) -> i32 { /* missing */ }",
        expected: "x * 2",
        match_mode: MatchMode::Contains,
    },
    Case {
        name: "complexity",
        prompt: "What is the average time complexity of binary search on a sorted array? Reply only in Big-O notation.",
        expected: "O(log n)",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "sql filter",
        prompt: "Write one SQL statement selecting only the `name` column from `users` rows where `active` equals 1. Reply with SQL only.",
        expected: "SELECT name FROM users WHERE active = 1;",
        match_mode: MatchMode::Exact,
    },
    Case {
        name: "javascript trace",
        prompt: "What does this JavaScript print? Reply with only the output.\n\nconsole.log([1, 2, 3, 4].filter(x => x % 2 === 0).length);",
        expected: "2",
        match_mode: MatchMode::Exact,
    },
];

pub struct Result {
    pub passed: u64,
    pub total: u64,
    pub score: f64,
}

fn cases(suite: Suite) -> &'static [Case] {
    match suite {
        Suite::Chat => &CHAT_CASES,
        Suite::Code => &CODE_CASES,
    }
}

fn canonical_answer(s: &str) -> String {
    let trimmed = s.trim();
    let without_fence = if trimmed.starts_with("```") && trimmed.ends_with("```") {
        let mut lines = trimmed.lines();
        lines.next();
        let mut body: Vec<&str> = lines.collect();
        if body.last().is_some_and(|line| line.trim() == "```") {
            body.pop();
        }
        body.join("\n")
    } else {
        trimmed.to_string()
    };

    without_fence
        .trim()
        .trim_matches(|c| matches!(c, '`' | '"' | '\''))
        .to_ascii_lowercase()
        .chars()
        .filter(|c| !c.is_ascii_whitespace())
        .collect::<String>()
        .trim_end_matches(['.', ';'])
        .to_string()
}

fn response_matches(response: &str, expected: &str, match_mode: MatchMode) -> bool {
    let response = canonical_answer(response);
    let expected = canonical_answer(expected);
    match match_mode {
        MatchMode::Exact => response == expected,
        MatchMode::Contains => response.contains(&expected),
    }
}

fn request(alias: &str, prompt: &str) -> std::result::Result<String, String> {
    let body = json!({
        "model": alias,
        "messages": [
            {
                "role": "system",
                "content": "Follow the requested output format exactly. Do not explain your answer."
            },
            {"role": "user", "content": prompt}
        ],
        "chat_template_kwargs": {"enable_thinking": false},
        "thinking_budget_tokens": 0,
        "temperature": 0,
        "max_tokens": 512,
        "stream": false
    });
    let output = Command::new("curl")
        .args([
            "-fsS",
            "--connect-timeout",
            "2",
            "--max-time",
            "600",
            "-H",
            "Content-Type: application/json",
            "-d",
            &body.to_string(),
            URL,
        ])
        .output()
        .map_err(|e| format!("cannot run curl: {e}"))?;
    if !output.status.success() {
        return Err(format!(
            "router request failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }

    let value: Value =
        serde_json::from_slice(&output.stdout).map_err(|e| format!("invalid router JSON: {e}"))?;
    value["choices"][0]["message"]["content"]
        .as_str()
        .or_else(|| value["choices"][0]["text"].as_str())
        .map(str::to_string)
        .ok_or_else(|| format!("router response has no answer: {value}"))
}

pub fn run(alias: &str, suite: Suite) -> std::result::Result<Result, String> {
    let cases = cases(suite);
    let mut passed = 0;
    for case in cases {
        let response = request(alias, case.prompt)?;
        let ok = response_matches(&response, case.expected, case.match_mode);
        println!(
            "  {:<20} {}  {}",
            case.name,
            if ok { "pass" } else { "FAIL" },
            response.trim().replace('\n', " ")
        );
        passed += u64::from(ok);
    }

    let total = cases.len() as u64;
    Ok(Result {
        passed,
        total,
        score: passed as f64 / total as f64 * 100.0,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_whitespace_case_and_code_fences() {
        assert!(response_matches(
            " COBALT-17\n",
            "cobalt-17",
            MatchMode::Exact
        ));
        assert!(response_matches(
            "```rust\nx * 2\n```",
            "x * 2",
            MatchMode::Exact
        ));
        assert!(response_matches(
            "select name from users where active=1",
            "SELECT name FROM users WHERE active = 1;",
            MatchMode::Exact
        ));
        assert!(response_matches(
            "fn double(x: i32) -> i32 { x * 2 }",
            "x * 2",
            MatchMode::Contains
        ));
    }

    #[test]
    fn rejects_explanations_and_wrong_answers() {
        assert!(!response_matches(
            "The answer is no.",
            "no",
            MatchMode::Exact
        ));
        assert!(!response_matches("39", "38", MatchMode::Exact));
    }
}
