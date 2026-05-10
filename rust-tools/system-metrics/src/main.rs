//! system-metrics: Replace for system-metrics.sh
//!
//! Reads CPU usage, CPU temp, load avg, memory, and GPU stats.
//! Outputs single JSON line consumed by MetricsState.qml.

use std::fs;
use std::process::Command;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

fn read_u64_from(path: &str) -> Option<u64> {
    let s = fs::read_to_string(path).ok()?;
    s.trim().parse().ok()
}

#[derive(serde::Serialize, serde::Deserialize, Clone, Copy, Debug)]
struct CpuTimes {
    user: u64,
    nice: u64,
    system: u64,
    idle: u64,
    iowait: u64,
    irq: u64,
    softirq: u64,
    steal: u64,
    timestamp: u64,
}

fn read_cpu_times() -> Option<CpuTimes> {
    let line = fs::read_to_string("/proc/stat").ok()?;
    let first = line.lines().next()?;
    let parts: Vec<&str> = first.split_whitespace().collect();
    if parts.is_empty() || parts[0] != "cpu" {
        return None;
    }
    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64;

    Some(CpuTimes {
        user: parts.get(1)?.parse().ok()?,
        nice: parts.get(2)?.parse().ok()?,
        system: parts.get(3)?.parse().ok()?,
        idle: parts.get(4)?.parse().ok()?,
        iowait: parts.get(5).and_then(|s| s.parse().ok()).unwrap_or(0),
        irq: parts.get(6).and_then(|s| s.parse().ok()).unwrap_or(0),
        softirq: parts.get(7).and_then(|s| s.parse().ok()).unwrap_or(0),
        steal: parts.get(8).and_then(|s| s.parse().ok()).unwrap_or(0),
        timestamp,
    })
}

fn total(t: &CpuTimes) -> u64 {
    t.user + t.nice + t.system + t.idle + t.iowait + t.irq + t.softirq + t.steal
}

fn idle(t: &CpuTimes) -> u64 {
    t.idle + t.iowait
}

fn cpu_usage_pct() -> Option<f64> {
    let current = read_cpu_times()?;
    let state_file = "/tmp/system-metrics-last-stat";

    let last: Option<CpuTimes> = if let Ok(content) = fs::read_to_string(state_file) {
        serde_json::from_str(&content).ok()
    } else {
        None
    };

    // Save current for next time
    if let Ok(json) = serde_json::to_string(&current) {
        let _ = fs::write(state_file, json);
    }

    if let Some(t1) = last {
        // Only use if not too old (max 30s)
        let delta_ms = current.timestamp.saturating_sub(t1.timestamp);
        if delta_ms > 0 && delta_ms < 30000 {
            let total_delta = total(&current).saturating_sub(total(&t1));
            let idle_delta = idle(&current).saturating_sub(idle(&t1));
            if total_delta > 0 {
                let busy = total_delta.saturating_sub(idle_delta);
                return Some(busy as f64 / total_delta as f64 * 100.0);
            }
        }
    }

    // Fallback: brief sleep if no state or state too old
    std::thread::sleep(Duration::from_millis(100));
    let t2 = read_cpu_times()?;
    let total_delta = total(&t2).saturating_sub(total(&current));
    let idle_delta = idle(&t2).saturating_sub(idle(&current));
    if total_delta == 0 {
        return None;
    }
    let busy = total_delta.saturating_sub(idle_delta);
    Some(busy as f64 / total_delta as f64 * 100.0)
}

fn cpu_temp() -> Option<String> {
    let mut best_temp = None;
    let mut best_priority = 0;

    // Try hwmon
    if let Ok(dir) = fs::read_dir("/sys/class/hwmon") {
        for entry in dir.filter_map(|e| e.ok()) {
            let path = entry.path();
            let name_path = path.join("name");
            if let Ok(name) = fs::read_to_string(&name_path) {
                let name = name.trim().to_lowercase();
                let priority = if name.contains("coretemp") {
                    10
                } else if name.contains("zenpower") || name.contains("k10temp") {
                    9
                } else if name.contains("cpu") {
                    5
                } else {
                    1
                };

                if priority >= best_priority {
                    if let Ok(hwmon_dir) = fs::read_dir(&path) {
                        for sub in hwmon_dir.filter_map(|e| e.ok()) {
                            let fname = sub.file_name().into_string().unwrap_or_default();
                            // temp1_input is usually the package or die temp
                            if fname == "temp1_input" {
                                if let Some(temp) = read_u64_from(&sub.path().to_string_lossy()) {
                                    best_temp = Some(format!("{:.0}°C", temp as f64 / 1000.0));
                                    best_priority = priority;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if best_temp.is_some() {
        return best_temp;
    }

    // Fallback to thermal zone
    if let Ok(dir) = fs::read_dir("/sys/class/thermal") {
        for entry in dir.filter_map(|e| e.ok()) {
            let path = entry.path();
            if path
                .file_name()
                .and_then(|n| n.to_str())
                .is_some_and(|n| n.starts_with("thermal_zone"))
            {
                if let Some(temp) = read_u64_from(&path.join("temp").to_string_lossy()) {
                    return Some(format!("{:.0}°C", temp as f64 / 1000.0));
                }
            }
        }
    }
    None
}

struct MemInfo {
    total_kb: u64,
    available_kb: u64,
}

fn read_meminfo() -> Option<MemInfo> {
    let contents = fs::read_to_string("/proc/meminfo").ok()?;
    let mut total = None;
    let mut available = None;
    for line in contents.lines() {
        if let Some(val) = line.strip_prefix("MemTotal:") {
            total = val.split_whitespace().next().and_then(|s| s.parse().ok());
        }
        if let Some(val) = line.strip_prefix("MemAvailable:") {
            available = val.split_whitespace().next().and_then(|s| s.parse().ok());
        }
    }
    Some(MemInfo {
        total_kb: total?,
        available_kb: available?,
    })
}

#[derive(serde::Serialize, Default)]
struct GpuInfo {
    usage: Option<u64>,
    temp: Option<String>,
    vram_used: Option<u64>,
    vram_total: Option<u64>,
}

fn gpu_info() -> GpuInfo {
    // Try nvidia-smi first
    let nvidia = Command::new("nvidia-smi")
        .args([
            "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total",
            "--format=csv,noheader,nounits",
        ])
        .output();

    if let Ok(out) = nvidia {
        if out.status.success() {
            let s = String::from_utf8_lossy(&out.stdout);
            let parts: Vec<&str> = s.split(',').map(|p| p.trim()).collect();
            if parts.len() >= 4 {
                return GpuInfo {
                    usage: parts[0].parse().ok(),
                    temp: Some(format!("{}°C", parts[1])),
                    vram_used: parts[2].parse().ok(),
                    vram_total: parts[3].parse().ok(),
                };
            }
        }
    }

    // Fallback to sysfs (AMD/Intel/Open NVIDIA)
    let mut info = GpuInfo::default();

    // Find a card with usage info
    if let Ok(dir) = fs::read_dir("/sys/class/drm") {
        for entry in dir.filter_map(|e| e.ok()) {
            let path = entry.path();
            let name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
            if !name.starts_with("card") || name.contains('-') {
                continue;
            }

            let device = path.join("device");

            // Usage
            if info.usage.is_none() {
                if let Some(u) = read_u64_from(&device.join("gpu_busy_percent").to_string_lossy()) {
                    info.usage = Some(u);
                }
            }

            // VRAM
            if info.vram_total.is_none() {
                if let Some(total) =
                    read_u64_from(&device.join("mem_info_vram_total").to_string_lossy())
                {
                    info.vram_total = Some(total / 1024 / 1024);
                    if let Some(used) =
                        read_u64_from(&device.join("mem_info_vram_used").to_string_lossy())
                    {
                        info.vram_used = Some(used / 1024 / 1024);
                    }
                }
            }

            // Temp
            if info.temp.is_none() {
                if let Ok(hw_dir) = fs::read_dir(device.join("hwmon")) {
                    for hw in hw_dir.filter_map(|e| e.ok()) {
                        if let Some(t) =
                            read_u64_from(&hw.path().join("temp1_input").to_string_lossy())
                        {
                            info.temp = Some(format!("{}°C", t / 1000));
                            break;
                        }
                    }
                }
            }
        }
    }

    info
}

fn load1() -> Option<f64> {
    let line = fs::read_to_string("/proc/loadavg").ok()?;
    line.split_whitespace().next().and_then(|s| s.parse().ok())
}

#[derive(serde::Serialize)]
struct Metrics {
    cpu: Option<f64>,
    cpu_temp: Option<String>,
    load1: Option<f64>,
    gpu: Option<u64>,
    gpu_temp: Option<String>,
    gpu_vram_used: Option<u64>,
    gpu_vram_total: Option<u64>,
    mem_used: f64,
    mem_total: f64,
}

fn main() {
    let cpu = cpu_usage_pct();
    let cpu_temp = cpu_temp();
    let load1 = load1();
    let gpu = gpu_info();
    let mem = read_meminfo().unwrap_or(MemInfo {
        total_kb: 0,
        available_kb: 0,
    });

    let mem_used_gb = (mem.total_kb.saturating_sub(mem.available_kb)) as f64 / 1024.0 / 1024.0;
    let mem_total_gb = mem.total_kb as f64 / 1024.0 / 1024.0;

    let metrics = Metrics {
        cpu,
        cpu_temp,
        load1,
        gpu: gpu.usage,
        gpu_temp: gpu.temp,
        gpu_vram_used: gpu.vram_used,
        gpu_vram_total: gpu.vram_total,
        mem_used: (mem_used_gb * 10.0).round() / 10.0,
        mem_total: (mem_total_gb * 10.0).round() / 10.0,
    };

    println!("{}", serde_json::to_string(&metrics).unwrap());
}
