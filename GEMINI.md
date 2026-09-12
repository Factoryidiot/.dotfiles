# Gemini Workspace Summary

This repository contains a collection of personal dotfiles used to configure a Linux desktop environment. The setup is centered around the Hyprland Wayland compositor and various other tools.

## My Role

My role is to help build out and maintain the configuration and consistency for this setup. I can assist with modifying existing files, creating new scripts, and ensuring a coherent and functional desktop experience.

## How This Repository Works

The configuration files within this `.dotfiles` directory are intended to be **symlinked** to their respective homes in the user's home directory (e.g., under `~/.config/`).

For example, the Hyprland configuration is linked like this:
`~/.dotfiles/hypr/hyprland.lua` -> `~/.config/hypr/hyprland.lua`
`~/.dotfiles/hypr/modules/` -> `~/.config/hypr/modules/`

This allows for version control of the configuration while keeping the files in the locations expected by their respective applications.

## Project Goals

1.  **Consistent Theming**: To create a consistent but easily changeable theme that applies across all relevant applications (Waybar, terminals, application launchers, etc.).
2.  **Auxiliary Scripts**: To develop a set of helper scripts in the `~/.dotfiles/bin/` directory to provide quick access to basic functions like opening TUI/web apps, managing the screensaver, and launching menus.

## Directory Structure & Purpose

- **`bin/`**: Contains utility shell scripts for managing desktop session tasks, such as launching applications, controlling screensavers, audio, weather, and window focus (`launch-or-focus-tui`, `cmd-screensaver`).

- **`cliamp/`**: Configuration for `cliamp`, the terminal music player.

- **`fastfetch/`**: Configuration for `fastfetch`, displaying system information in the terminal.

- **`ghostty/`**: Configuration for the `ghostty` terminal emulator and screensaver terminal instance.

- **`hypr/`**: Hyprland compositor configuration using native Lua (`hyprland.lua` & `modules/`) alongside auxiliary daemon configs (`hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `theme.conf`).

- **`quickshell/`**: Desktop shell and notification daemon written in QML (top status bar, menus, volume/brightness/battery monitors, and native DBus notification daemon).

- **`starship/`**: Configuration for the `starship` cross-shell prompt (`starship.toml`).

- **`tmux/`**: Configuration for `tmux`, the terminal multiplexer.

- **`vm-curator/`**: Configuration for `vm-curator`, managing local virtual machines.

- **`weather/`**: Configuration (`locations.json`) for local weather fetching and reporting.