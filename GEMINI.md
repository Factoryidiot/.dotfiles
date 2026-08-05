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

- **`bin/`**: Contains various utility shell scripts for managing the desktop session, such as launching applications, handling screensavers (`screensaver.txt`, `toggle-screensaver`), and managing window focus (`launch-or-focus`).

- **`elephant/`**: Holds configuration files (`.toml`) for what appears to be an application menu or launcher system.

- **`fastfetch/`**: Configuration for `fastfetch`, a tool for displaying system information in the terminal.

- **`flatpak/`**: Contains configuration for Flatpak, a sandboxed application packaging format.

- **`github/`**: Includes environment setup scripts (`env.sh`) likely used for configuring Git or GitHub-related tools.

- **`hypr/`**: This is the core of the desktop configuration, using Lua configuration files (`hyprland.lua` & `modules/`) alongside auxiliary daemon configs (`hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `theme.conf`):
    - `hyprland.lua`: Main Lua entry point loading `modules/`.
    - `modules/`: Modular Lua configuration files (autostart, envs, input, looknfeel, monitors, windows, keybindings).
    - `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `theme.conf`: Configuration for idle management, screen locking, blue-light control, and lockscreen themes.
    - `deprecated/`: Holds legacy `.conf` files (`autostart.conf`, `envs.conf`, `hyprland.conf`, `input.conf`, `keybindings.conf`, `looknfeel.conf`, `monitors.conf`, `windows.conf`).

- **`tmux/`**: Configuration for `tmux`, a terminal multiplexer.

- **`walker/`**: Configuration and styling (`.xml`, `.css`) for `walker`, which seems to be an application runner or launcher.

- **`waybar/`**: Configuration (`config.jsonc`) and styling (`style.css`) for `waybar`, a status bar for Wayland compositors.

- **`zsh/`**: Contains configuration files for the Zsh shell, including prompt customization with Powerlevel10k (`.p10k.zsh`).