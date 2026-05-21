-- -----------------------------------------------------
-- Base System Window Rules, Floaters, & Overrides
-- -----------------------------------------------------

-- Global Event Suppression
hl.window_rule({
    match = { class = "^(.*)$" },
    suppress_event = "maximize"
})

-- 1. Floating Windows Configuration & Custom Tagging
hl.window_rule({
    match = { 
        class = "dot.nix.manage-vms|dot.nix.display-keybindings|dot.nix.bluetui|dot.nix.impala|dot.nix.wiremix|dot.nix.btop|dot.nix.terminal|dot.nix.yazi|org.gnome.NautilusPreviewer|dot.nix.Evince|com.gabm.satty|Whio|About|TUI.float|imv|mpv|dot.nix.install-vm" 
    },
    tag = "+floating-window"
})

hl.window_rule({
    match = { 
        class = "brave|xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus", 
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to (open|save).*|[C|c]hoose.*)" 
    },
    tag = "+floating-window"
})

-- 2. Behavioral Rules applied to 'floating-window' tag
hl.window_rule({
    match = { tag = "floating-window" },
    float = true,
    tile = false,
    center = true,
    size = { 875, 600 }
})

-- Specific size overrides for specialized Nix tools
hl.window_rule({
    match = { class = "dot.nix.display-about" },
    float = true,
    center = true,
    size = { 955, 525 }
})

hl.window_rule({
    match = { class = "dot.nix.display-keybindings|dot.nix.install-webapp|dot.nix.uninstall-webapp" },
    float = true,
    center = true,
    size = { 875, 600 }
})

hl.window_rule({
    match = { class = "org.gnome.Calculator" },
    float = true
})

-- General Visuals & Opacities
hl.window_rule({
    match = { class = "^(.*)$" },
    opacity = "0.97 0.9"
})

hl.window_rule({
    match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$" },
    opacity = "1.0 1.0"
})

hl.window_rule({
    match = { tag = "pop" },
    rounding = 8
})

-- XWayland Unfocused Fixes
hl.window_rule({
    match = { 
        class = "^$", 
        title = "^$", 
        xwayland = true, 
        float = true, 
        fullscreen = false, 
        pin = false 
    },
    no_initial_focus = true
})

-- Nix Screensaver Overrides
hl.window_rule({
    match = { class = "dot.nix.screensaver" },
    fullscreen = true,
    float = true,
    opacity = "1.0 override 1.0 override", -- The new API infers override when values are explicitly flat 1.0 targets
    no_shadow = true
})

-- Idle Inhibition
hl.window_rule({
    match = { tag = "noidle" },
    idle_inhibit = "always"
})

-- Terminals & Inputs
hl.window_rule({
    match = { class = "Alacritty" },
    tag = "+terminal"
    -- Note: scroll_touchpad is a per-device input option config block setting rather than a window rules effect,
    -- so it has been omitted here. It should live inside your hl.config input table blocks.
})
