-- -----------------------------------------------------
-- Application Launchers & Session Management
-- -----------------------------------------------------

-- [Launchers]
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd([[uwsm-app -- xdg-terminal-exec --dir="$(cmd-terminal-cwd)"]]), { desc = "Terminal" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("launch-menu-applications"), { desc = "Application menu" })
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("launch-menu"), { desc = "Menu" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("launch-or-focus-tui yazi"), { desc = "File manager" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("uwsm-app -- firefox"), { desc = "Web browser" })

-- [Flatpak]
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd([[launch-or-focus ^bitwarden$ "uwsm-app -- bitwarden.desktop -disable-gpu --enable-wayland-ime"]]), { desc = "Password manager" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd([[launch-or-focus ^obsidian$ "uwsm-app -- flatpak run md.obsidian.Obsidian -disable-gpu --enable-wayland-ime"]]), { desc = "Notes" })

-- [Webapps]
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd('launch-webapp "https://calendar.google.com/"'), { desc = "Calendar" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd('launch-webapp "https://gmail.com/"'), { desc = "Gmail" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd('launch-webapp "https://gemini.google.com/"'), { desc = "Gemini" })
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.exec_cmd('launch-webapp "https://chat.google.com/"'), { desc = "Chat" })
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd('launch-webapp "https://youtube.com/"'), { desc = "YouTube" })

-- [Clipboard]
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | walker --dmenu | cliphist decode | wl-copy"), { desc = "Clipboard manager" })

-- [Session]
-- Hand off the exit sequence to UWSM for clean systemd scope termination
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("uwsm stop"), { desc = "Exit Hyprland (UWSM)" })

hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("toggle-idle"), { desc = "Toggle idle" })
