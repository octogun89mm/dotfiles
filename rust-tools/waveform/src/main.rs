//! waveform: Replaces waveform.sh (parec + python3 one-liner)
//!
//! Outputs one envelope frame per chunk: <signed_mean>;<peak_amplitude>
//! Both in -1..1 range at ~60Hz (CHUNK=134 samples at 8000Hz).
//!
//! Spawns `parec` internally instead of piping from shell.

use std::io::{self, Read};
use std::process::{Command, Stdio};

const SAMPLE_RATE: u32 = 8000;
const CHANNELS: u32 = 1;
const CHUNK: usize = 134; // ~60Hz at 8000Hz

fn main() {
    // Get default sink
    let sink = get_default_sink().unwrap_or_else(|| {
        eprintln!("waveform: no default sink");
        std::process::exit(1);
    });

    // Spawn parec
    let monitor = format!("{}.monitor", sink);
    let mut child = Command::new("parec")
        .args([
            "--format=s16le",
            &format!("--rate={}", SAMPLE_RATE),
            &format!("--channels={}", CHANNELS),
            "-d",
            &monitor,
            "--raw",
        ])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .unwrap_or_else(|e| {
            eprintln!("waveform: failed to start parec: {}", e);
            std::process::exit(1);
        });

    let stdout = child.stdout.take().unwrap();
    let mut reader = io::BufReader::new(stdout);
    let mut buf = [0u8; CHUNK * 2]; // 2 bytes per sample

    loop {
        let mut bytes_read = 0;
        while bytes_read < buf.len() {
            match reader.read(&mut buf[bytes_read..]) {
                Ok(0) => break,
                Ok(n) => bytes_read += n,
                Err(e) => {
                    eprintln!("waveform: read error: {}", e);
                    std::process::exit(1);
                }
            }
        }

        if bytes_read == 0 {
            break;
        }

        let n = bytes_read / 2;
        if n == 0 {
            continue;
        }

        let mut sum: i64 = 0;
        let mut peak_abs: i16 = 0;

        for i in 0..n {
            let sample = i16::from_ne_bytes([buf[i * 2], buf[i * 2 + 1]]);
            sum += sample as i64;
            let abs = sample.abs();
            if abs > peak_abs {
                peak_abs = abs;
            }
        }

        let avg = sum as f64 / n as f64 / 32768.0;
        let peak = peak_abs as f64 / 32768.0;

        println!("{:.4};{:.4}", avg, peak);
    }

    let _ = child.wait();
}

fn get_default_sink() -> Option<String> {
    // Try pactl info first
    let output = Command::new("pactl").args(["info"]).output().ok()?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines() {
        if let Some(name) = line.strip_prefix("Default Sink: ") {
            return Some(name.trim().to_string());
        }
    }

    // Fall back to reading the pacmd default
    let output = Command::new("pactl")
        .args(["get-default-sink"])
        .output()
        .ok()?;
    let name = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if name.is_empty() {
        None
    } else {
        Some(name)
    }
}
