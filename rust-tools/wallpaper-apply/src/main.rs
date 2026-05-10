//! wallpaper-apply: Replaces wallpaper-apply.sh
//!
//! Usage: wallpaper-apply <image-path>

use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;

fn main() {
    let args: Vec<String> = env::args().collect();
    let wallpaper = match args.get(1) {
        Some(p) => p.as_str(),
        None => {
            eprintln!("Usage: {} <wallpaper-image>", args[0]);
            std::process::exit(2);
        }
    };

    if !Path::new(wallpaper).exists() {
        eprintln!("wallpaper not found: {}", wallpaper);
        std::process::exit(1);
    }

    let home = env::var("HOME").expect("HOME not set");
    let name = Path::new(wallpaper)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("wallpaper");

    // Preload and set wallpaper via hyprpaper
    run_cmd("hyprctl", &["hyprpaper", "preload", wallpaper]);
    run_cmd("hyprctl", &["hyprpaper", "wallpaper", &format!(",{}", wallpaper)]);
    run_cmd("hyprctl", &["hyprpaper", "unload", "unused"]);

    // Write hyprpaper.conf
    let hyprpaper_conf = format!("{}/.config/hypr/hyprpaper.conf", home);
    if let Some(parent) = Path::new(&hyprpaper_conf).parent() {
        fs::create_dir_all(parent).ok();
    }
    let conf_content = format!(
        "splash = false\n\nwallpaper {{\n    monitor =\n    path = {}\n}}\n",
        wallpaper
    );
    fs::write(&hyprpaper_conf, &conf_content).ok();

    // Run wallust
    run_cmd("wallust", &["run", wallpaper]);

    // Write cache files
    let cache_dir = format!("{}/.cache", home);
    fs::create_dir_all(&cache_dir).ok();
    write_file(&format!("{}/wallust-current-theme", cache_dir), name);
    write_file(&format!("{}/wallust-current-wallpaper", cache_dir), wallpaper);
    write_file(&format!("{}/wallust-current-source", cache_dir), "wallpaper");
    write_file(&format!("{}/quickshell-theme-picker-mode", cache_dir), "wallpaper");

    // Reload services
    run_cmd("hyprctl", &["reload"]);
    run_cmd("dunstctl", &["reload"]);

    // Update kitty colors
    let kitty_colors = format!("{}/.config/kitty/themes/wallust.conf", home);
    if Path::new(&kitty_colors).exists() {
        run_cmd("kitty", &["@", "set-colors", "--all", "--configured", &kitty_colors]);
    }

    // Notify
    run_cmd("notify-send", &[
        "-a", "Wallpaper",
        "-u", "low",
        "-t", "2500",
        "Wallpaper",
        &format!("Set to {}", name),
    ]);

    // Restart quickshell
    let restart_bin = format!("{}/.dotfiles/rust-tools/target/release/quickshell-restart", home);
    if Path::new(&restart_bin).exists() {
        run_cmd_detached(&restart_bin, &[]);
    }
}

fn run_cmd(cmd: &str, args: &[&str]) {
    Command::new(cmd)
        .args(args)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .ok();
}

fn run_cmd_detached(cmd: &str, args: &[&str]) {
    Command::new(cmd)
        .args(args)
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
        .ok();
}

fn write_file(path: &str, contents: &str) {
    if let Some(parent) = Path::new(path).parent() {
        fs::create_dir_all(parent).ok();
    }
    fs::write(path, contents).ok();
}
