//! Ratatui front-end: an action picker and a two-pane model picker.
//!
//! The model picker is the whole point of the rewrite — a list on the left,
//! a live stats card plus a recent-tokens/s sparkline on the right, all
//! colour-coded so a glance tells you which models earn their disk space.

use std::io;

use crate::meta::truncate;
use ratatui::{
    crossterm::event::{self, Event, KeyCode, KeyEventKind},
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Color, Modifier, Style, Stylize},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Sparkline, Wrap},
    DefaultTerminal, Frame,
};

/// Everything the preview needs, pre-computed so the TUI never touches the DB.
pub struct ModelView {
    pub alias: String,
    pub desc: Option<String>,
    pub configured: bool,
    pub path: String,
    pub missing: bool,
    pub size: String,
    pub quant: String,
    pub ctx: String,
    pub offload: String,
    pub kv_cache: String,
    pub spec: Option<String>,
    pub launches: u64,
    pub last_used: String,
    pub tg_avg: Option<f64>,
    pub tg_min: Option<f64>,
    pub tg_max: Option<f64>,
    pub tg_n: u64,
    pub pp_avg: Option<f64>,
    pub pp_n: u64,
    pub chat_score: Option<f64>,
    pub code_score: Option<f64>,
    pub spark: Vec<u64>,
}

const ACCENT: Color = Color::Cyan;

fn speed_color(avg: Option<f64>) -> Color {
    match avg {
        None => Color::DarkGray,
        Some(v) if v < 8.0 => Color::Red,
        Some(v) if v < 20.0 => Color::Yellow,
        Some(_) => Color::Green,
    }
}

fn fmt_speed(v: Option<f64>) -> String {
    v.map(|x| format!("{x:.0}")).unwrap_or_else(|| "—".into())
}

fn fmt_score(v: Option<f64>) -> String {
    v.map(|x| format!("{x:.0}/100"))
        .unwrap_or_else(|| "not run".into())
}

/// Average of whichever benchmark scores exist, if any.
fn bench_avg(m: &ModelView) -> Option<f64> {
    match (m.chat_score, m.code_score) {
        (Some(c), Some(d)) => Some((c + d) / 2.0),
        (Some(s), None) | (None, Some(s)) => Some(s),
        (None, None) => None,
    }
}

/// Below this benchmark average a model is failing more than it passes.
const BENCH_FLUNK: f64 = 40.0;

/// A blunt keep/cull recommendation, the feature the user actually asked for.
pub fn verdict(m: &ModelView) -> (String, Color) {
    if m.missing {
        return ("file missing — drop the INI entry".into(), Color::Red);
    }
    let bench = bench_avg(m);
    if m.launches == 0 && m.tg_n == 0 {
        // Benchmarks run through the router, which never records a launch, so
        // a benched-but-unlaunched model is not automatically cull bait.
        return match bench {
            Some(b) if b < BENCH_FLUNK => (
                format!("flunks benchmarks ({b:.0}/100) — cull candidate"),
                Color::Red,
            ),
            Some(b) => (
                format!("benchmarked {b:.0}/100 — launch it to measure speed"),
                Color::DarkGray,
            ),
            None => ("never launched — cull candidate".into(), Color::Magenta),
        };
    }
    if m.tg_n == 0 {
        return (
            "no speed data yet — launch it to measure".into(),
            Color::DarkGray,
        );
    }
    match (m.tg_avg, bench) {
        (Some(v), _) if v < 8.0 => (
            format!("slow (~{v:.0} t/s) — keep only if you need it"),
            Color::Red,
        ),
        (Some(v), Some(b)) if b < BENCH_FLUNK => (
            format!("{v:.0} t/s but flunks benchmarks ({b:.0}/100)"),
            Color::Yellow,
        ),
        (Some(v), _) if v < 20.0 => (format!("usable (~{v:.0} t/s)"), Color::Yellow),
        _ => ("healthy — keep".into(), Color::Green),
    }
}

/// Move a list selection with wraparound.
fn step(state: &mut ListState, len: usize, delta: isize) {
    if len == 0 {
        return;
    }
    let cur = state.selected().unwrap_or(0) as isize;
    let next = (cur + delta).rem_euclid(len as isize) as usize;
    state.select(Some(next));
}

/// Simple single-column picker (used for the action menu). Returns the chosen
/// index, or `None` if the user backed out.
pub fn pick_action(
    term: &mut DefaultTerminal,
    title: &str,
    items: &[(String, String)],
) -> io::Result<Option<usize>> {
    let mut state = ListState::default();
    state.select(Some(0));

    loop {
        term.draw(|f| draw_action(f, title, items, &mut state))?;

        if let Event::Key(k) = event::read()? {
            if k.kind != KeyEventKind::Press {
                continue;
            }
            match k.code {
                KeyCode::Char('q') | KeyCode::Esc => return Ok(None),
                KeyCode::Char('j') | KeyCode::Down => step(&mut state, items.len(), 1),
                KeyCode::Char('k') | KeyCode::Up => step(&mut state, items.len(), -1),
                KeyCode::Char('g') | KeyCode::Home => state.select(Some(0)),
                KeyCode::Char('G') | KeyCode::End => {
                    state.select(Some(items.len().saturating_sub(1)))
                }
                KeyCode::Enter => return Ok(state.selected()),
                _ => {}
            }
        }
    }
}

fn draw_action(f: &mut Frame, title: &str, items: &[(String, String)], state: &mut ListState) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(1)])
        .split(f.area());

    let rows: Vec<ListItem> = items
        .iter()
        .map(|(key, label)| {
            ListItem::new(Line::from(vec![
                Span::styled(format!("{key:<8}"), Style::default().fg(ACCENT).bold()),
                Span::raw(label.clone()),
            ]))
        })
        .collect();

    let list = List::new(rows)
        .block(Block::default().borders(Borders::ALL).title(Span::styled(
            format!(" {title} "),
            Style::default().fg(ACCENT).bold(),
        )))
        .highlight_symbol("▌ ")
        .highlight_style(
            Style::default()
                .add_modifier(Modifier::BOLD)
                .bg(Color::Rgb(40, 40, 50)),
        );
    f.render_stateful_widget(list, chunks[0], state);

    f.render_widget(
        Paragraph::new(Span::styled(
            " j/k move · Enter select · q/Esc quit ",
            Style::default().fg(Color::DarkGray),
        )),
        chunks[1],
    );
}

/// The rich two-pane model picker. Returns the chosen model index, or `None`.
pub fn pick_model(term: &mut DefaultTerminal, models: &[ModelView]) -> io::Result<Option<usize>> {
    if models.is_empty() {
        return Ok(None);
    }
    let mut state = ListState::default();
    state.select(Some(0));

    loop {
        term.draw(|f| draw_model(f, models, &mut state))?;

        if let Event::Key(k) = event::read()? {
            if k.kind != KeyEventKind::Press {
                continue;
            }
            match k.code {
                KeyCode::Char('q') | KeyCode::Esc => return Ok(None),
                KeyCode::Char('j') | KeyCode::Down => step(&mut state, models.len(), 1),
                KeyCode::Char('k') | KeyCode::Up => step(&mut state, models.len(), -1),
                KeyCode::Char('g') | KeyCode::Home => state.select(Some(0)),
                KeyCode::Char('G') | KeyCode::End => state.select(Some(models.len() - 1)),
                KeyCode::Enter => return Ok(state.selected()),
                _ => {}
            }
        }
    }
}

fn draw_model(f: &mut Frame, models: &[ModelView], state: &mut ListState) {
    let outer = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(1)])
        .split(f.area());

    let panes = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(42), Constraint::Percentage(58)])
        .split(outer[0]);

    // --- left: model list ---
    let rows: Vec<ListItem> = models
        .iter()
        .map(|m| {
            let name_style = if m.missing {
                Style::default().fg(Color::Red).add_modifier(Modifier::DIM)
            } else if m.launches == 0 {
                Style::default().add_modifier(Modifier::DIM)
            } else {
                Style::default()
            };
            ListItem::new(Line::from(vec![
                Span::styled(format!("{:<18}", truncate(&m.alias, 18)), name_style),
                Span::styled(
                    if m.configured { " INI " } else { "disk " },
                    Style::default().fg(if m.configured {
                        Color::DarkGray
                    } else {
                        Color::Magenta
                    }),
                ),
                Span::styled(
                    format!("{:>3}× ", m.launches),
                    Style::default().fg(Color::DarkGray),
                ),
                Span::styled(
                    format!("{:>4} t/s", fmt_speed(m.tg_avg)),
                    Style::default().fg(speed_color(m.tg_avg)),
                ),
            ]))
        })
        .collect();

    let list = List::new(rows)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(Span::styled(" models ", Style::default().fg(ACCENT).bold())),
        )
        .highlight_symbol("▌ ")
        .highlight_style(
            Style::default()
                .add_modifier(Modifier::BOLD)
                .bg(Color::Rgb(40, 40, 50)),
        );
    f.render_stateful_widget(list, panes[0], state);

    // --- right: preview for the highlighted model ---
    let m = &models[state.selected().unwrap_or(0)];
    let right = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(6)])
        .split(panes[1]);

    f.render_widget(detail_paragraph(m), right[0]);
    f.render_widget(spark_widget(m), right[1]);

    // --- footer ---
    f.render_widget(
        Paragraph::new(Span::styled(
            " j/k move · g/G top/bottom · Enter launch · q/Esc back ",
            Style::default().fg(Color::DarkGray),
        )),
        outer[1],
    );
}

fn kv(label: &str, value: impl Into<String>) -> Line<'static> {
    Line::from(vec![
        Span::styled(format!("{label:<13}"), Style::default().fg(Color::DarkGray)),
        Span::raw(value.into()),
    ])
}

fn detail_paragraph(m: &ModelView) -> Paragraph<'static> {
    let mut lines: Vec<Line> = Vec::new();

    if let Some(d) = &m.desc {
        lines.push(Line::from(Span::styled(
            d.clone(),
            Style::default()
                .fg(Color::White)
                .add_modifier(Modifier::ITALIC),
        )));
        lines.push(Line::raw(""));
    }

    let size_span = if m.missing {
        Span::styled(
            "MISSING".to_string(),
            Style::default().fg(Color::Red).bold(),
        )
    } else {
        Span::raw(m.size.clone())
    };
    lines.push(Line::from(vec![
        Span::styled(
            format!("{:<13}", "Size / quant"),
            Style::default().fg(Color::DarkGray),
        ),
        size_span,
        Span::raw("  "),
        Span::styled(m.quant.clone(), Style::default().fg(ACCENT)),
    ]));
    lines.push(kv("Context", m.ctx.clone()));
    lines.push(Line::from(vec![
        Span::styled(
            format!("{:<13}", "Profile"),
            Style::default().fg(Color::DarkGray),
        ),
        Span::styled(
            if m.configured {
                "configured INI"
            } else {
                "unconfigured defaults"
            },
            Style::default().fg(if m.configured {
                Color::White
            } else {
                Color::Magenta
            }),
        ),
    ]));
    lines.push(kv("KV cache", m.kv_cache.clone()));
    lines.push(kv("Offload", m.offload.clone()));
    if let Some(spec) = &m.spec {
        lines.push(kv("Spec", spec.clone()));
    }
    lines.push(kv("File", truncate(&m.path, 44)));
    lines.push(Line::raw(""));

    lines.push(kv(
        "Launches",
        format!("{}    (last: {})", m.launches, m.last_used),
    ));

    let gen = match m.tg_avg {
        Some(avg) => format!(
            "{avg:.1} t/s  (min {} / max {}, n={})",
            fmt_speed(m.tg_min),
            fmt_speed(m.tg_max),
            m.tg_n
        ),
        None => "no samples yet".to_string(),
    };
    lines.push(Line::from(vec![
        Span::styled(
            format!("{:<13}", "Gen speed"),
            Style::default().fg(Color::DarkGray),
        ),
        Span::styled(gen, Style::default().fg(speed_color(m.tg_avg))),
    ]));

    let prompt = match m.pp_avg {
        Some(avg) => format!("{avg:.0} t/s  (n={})", m.pp_n),
        None => "no samples yet".to_string(),
    };
    lines.push(kv("Prompt speed", prompt));
    lines.push(kv("Chat score", fmt_score(m.chat_score)));
    lines.push(kv("Code score", fmt_score(m.code_score)));
    lines.push(Line::raw(""));

    let (text, color) = verdict(m);
    lines.push(Line::from(vec![
        Span::styled("Verdict      ", Style::default().fg(Color::DarkGray)),
        Span::styled(text, Style::default().fg(color).bold()),
    ]));

    Paragraph::new(lines).wrap(Wrap { trim: true }).block(
        Block::default().borders(Borders::ALL).title(Span::styled(
            format!(" {} ", m.alias),
            Style::default().fg(ACCENT).bold(),
        )),
    )
}

fn spark_widget(m: &ModelView) -> Sparkline<'static> {
    let title = if m.spark.is_empty() {
        " recent gen t/s — none yet ".to_string()
    } else {
        format!(" recent gen t/s ({} samples) ", m.spark.len())
    };
    Sparkline::default()
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(Span::styled(title, Style::default().fg(Color::DarkGray))),
        )
        .data(&m.spark)
        .style(Style::default().fg(speed_color(m.tg_avg)))
}

/// Centre a one-shot message (used when there is nothing to pick). Unused for
/// now but kept tiny in case the model list is empty.
#[allow(dead_code)]
pub fn flash(term: &mut DefaultTerminal, msg: &str) -> io::Result<()> {
    term.draw(|f| {
        let p = Paragraph::new(msg.to_string())
            .alignment(Alignment::Center)
            .block(Block::default().borders(Borders::ALL));
        f.render_widget(p, f.area());
    })?;
    let _ = event::read();
    Ok(())
}
