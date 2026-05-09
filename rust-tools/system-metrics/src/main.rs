//! system-metrics: Replace for system-metrics.sh
//!
//! Reads CPU usage, CPU temp, load avg, memory, and GPU stats.
//! Outputs single JSON line consumed by MetricsState.qml.
//!
//! Instead of shelling out to eww-bar, reads /proc directly.

use std::fs;
use std::path::Path;
use std::time::Duration;

fn read_u64_from(path: &str) -> Option<u64> {
    let s = fs::read_to_string(path).ok()?;
    s.trim().parse().ok()
}

fn read_line(path: &str) -> Option<String> {
    fs::read_to_string(path).ok().map(|s| s.trim().to_string())
}

struct CpuTimes {
    user: u64,
    nice: u64,
    system: u64,
    idle: u64,
    iowait: u64,
    irq: u64,
    softirq: u64,
    steal: u64,
}

fn read_cpu_times() -> Option<CpuTimes> {
    let line = fs::read_to_string("/proc/stat").ok()?;
    let first = line.lines().next()?;
    let parts: Vec<&str> = first.split_whitespace().collect();
    if parts.is_empty() || parts[0] != "cpu" {
        return None;
    }
    Some(CpuTimes {
        user: parts.get(1)?.parse().ok()?,
        nice: parts.get(2)?.parse().ok()?,
        system: parts.get(3)?.parse().ok()?,
        idle: parts.get(4)?.parse().ok()?,
        iowait: parts.get(5).and_then(|s| s.parse().ok()).unwrap_or(0),
        irq: parts.get(6).and_then(|s| s.parse().ok()).unwrap_or(0),
        softirq: parts.get(7).and_then(|s| s.parse().ok()).unwrap_or(0),
        steal: parts.get(8).and_then(|s| s.parse().ok()).unwrap_or(0),
    })
}

fn total(t: &CpuTimes) -> u64 {
    t.user + t.nice + t.system + t.idle + t.iowait + t.irq + t.softirq + t.steal
}

fn idle(t: &CpuTimes) -> u64 {
    t.idle + t.iowait
}

fn cpu_usage_pct() -> Option<f64> {
    let t1 = read_cpu_times()?;
    std::thread::sleep(Duration::from_millis(200));
    let t2 = read_cpu_times()?;

    let total_delta = total(&t2).saturating_sub(total(&t1));
    let idle_delta = idle(&t2).saturating_sub(idle(&t1));

    if total_delta == 0 {
        return None;
    }
    let busy = total_delta.saturating_sub(idle_delta);
    Some(busy as f64 / total_delta as f64 * 100.0)
}

fn cpu_temp() -> Option<String> {
    // Try thermal zone
    if let Ok(dir) = fs::read_dir("/sys/class/thermal") {
        for entry in dir.filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.file_name().and_then(|n| n.to_str()).map_or(false, |n| n.starts_with("thermal_zone")) {
                if let Some(temp) = read_u64_from(&path.join("temp").to_string_lossy()) {
                    return Some(format!("{:.0}°C", temp as f64 / 1000.0));
                }
            }
        }
    }
    // Try hwmon
    if let Ok(dir) = fs::read_dir("/sys/class/hwmon") {
        for entry in dir.filter_map(|e| e.ok()) {
            let path = entry.path();
            let name_path = path.join("name");
            if let Ok(name) = fs::read_to_string(&name_path) {
                let name = name.trim().to_lowercase();
                // Look for CPU sensors: coretemp, k8temp, k10temp, zenpower
                if name.contains("coretemp") || name.contains("k8temp") || name.contains("k10temp") || name.contains("zenpower") {
                    if let Ok(hwmon_dir) = fs::read_dir(&path) {
                        for sub in hwmon_dir.filter_map(|e| e.ok()) {
                            let fname = sub.file_name().into_string().unwrap_or_default();
                            if fname.starts_with("temp") && fname.ends_with("_input") {
                                if let Some(temp) = read_u64_from(&sub.path().to_string_lossy()) {
                                    return Some(format!("{:.0}°C", temp as f64 / 1000.0));
                                }
                            }
                        }
                    }
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
            total = val.trim().split_whitespace().next().and_then(|s| s.parse().ok());
        }
        if let Some(val) = line.strip_prefix("MemAvailable:") {
            available = val.trim().split_whitespace().next().and_then(|s| s.parse().ok());
        }
    }
    Some(MemInfo {
        total_kb: total?,
        available_kb: available?,
    })
}

#[derive(serde::Serialize)]
struct GpuInfo {
    usage: Option<u64>,
    temp: Option<String>,
    vram_used: Option<u64>,
    vram_total: Option<u64>,
}

fn gpu_info() -> GpuInfo {
    // Try nvidia first
    let nvidia_usage = read_line("/sys/class/drm/card0/device/gpu_busy_percent")
        .and_then(|s| s.parse::<u64>().ok());
    let nvidia_temp = read_u64_from("/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input")
        .or_else(|| {
            // Try glob-like pattern with explicit paths
            let base = "/sys/class/drm/card0/device";
            if let Ok(dir) = fs::read_dir(base) {
                for entry in dir.filter_map(|e| e.ok()) {
                    let p = entry.path();
                    if p.file_name().and_then(|n| n.to_str()).map_or(false, |n| n.starts_with("hwmon")) {
                        let temp = p.join("temp1_input");
                        if let Ok(t) = fs::read_to_string(&temp) {
                            return t.trim().parse::<u64>().ok();
                        }
                    }
                }
            }
            None
        })
        .map(|t| format!("{}°C", t / 1000));

    let (vram_used, vram_total) = if Path::new("/sys/class/drm/card1/device/mem_info_vram_total").exists() {
        // AMD
        let total = read_u64_from("/sys/class/drm/card1/device/mem_info_vram_total")
            .map(|b| b / 1024 / 1024);
        let used = read_u64_from("/sys/class/drm/card1/device/mem_info_vram_used")
            .map(|b| b / 1024 / 1024);
        (used, total)
    } else if Path::new("/proc/driver/nvidia/gpus/0/information").exists() {
        // NVIDIA - not easily read from sysfs, skip
        (None, None)
    } else {
        (None, None)
    };

    GpuInfo {
        usage: nvidia_usage,
        temp: nvidia_temp,
        vram_used,
        vram_total,
    }
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
    let mem = read_meminfo().unwrap_or(MemInfo { total_kb: 0, available_kb: 0 });

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
