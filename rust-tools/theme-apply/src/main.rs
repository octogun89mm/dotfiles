//! theme-apply: Replaces theme-apply.sh
//!
//! Usage: theme-apply <theme-name>
//!
//! Runs wallust cs/theme, updates cache, reloads hyprland/dunst/kitty, restarts quickshell.

use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;

fn main() {
    let args: Vec<String> = env::args().collect();
    let theme = match args.get(1) {
        Some(t) => t.as_str(),
        None => {
            eprintln!("Usage: {} <wallust-theme-or-colorscheme>", args[0]);
            std::process::exit(2);
        }
    };

    let home = env::var("HOME").expect("HOME not set");
    let colorscheme = format!("{}/.config/wallust/colorschemes/{}.json", home, theme);

    let mode = if theme.to_lowercase().contains("light")
        || theme.to_lowercase().contains("day")
        || theme.to_lowercase().contains("dawn")
        || theme.to_lowercase().contains("white")
        || theme.to_lowercase().contains("latte")
        || theme.to_lowercase().contains("fruitager")
    {
        "light"
    } else {
        "dark"
    };

    // Run wallust
    if Path::new(&colorscheme).exists() {
        run_cmd("wallust", &["cs", theme]);
    } else {
        run_cmd("wallust", &["theme", theme]);
    }

    // Write cache files
    let cache_dir = format!("{}/.cache", home);
    fs::create_dir_all(&cache_dir).ok();
    write_file(&format!("{}/wallust-current-theme", cache_dir), theme);
    write_file(&format!("{}/wallust-current-mode", cache_dir), mode);
    write_file(&format!("{}/wallust-current-source", cache_dir), "theme");
    write_file(
        &format!("{}/quickshell-theme-picker-mode", cache_dir),
        "theme",
    );

    // Reload services
    run_cmd("hyprctl", &["reload"]);
    run_cmd("dunstctl", &["reload"]);

    // Update kitty colors
    let kitty_colors = format!("{}/.config/kitty/themes/wallust.conf", home);
    if Path::new(&kitty_colors).exists() {
        run_cmd(
            "kitty",
            &["@", "set-colors", "--all", "--configured", &kitty_colors],
        );
    }

    // Restart quickshell
    let restart_bin = format!(
        "{}/.dotfiles/rust-tools/target/release/quickshell-restart",
        home
    );
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
