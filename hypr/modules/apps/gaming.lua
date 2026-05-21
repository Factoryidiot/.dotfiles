-- -----------------------------------------------------
-- Virtualization, Media Tools, and Gaming Ecosystems
-- -----------------------------------------------------

-- Native QEMU Development Workstation overrides
hl.window_rule({
    match = { class = "^(qemu)$" },
    opacity = "1 1",
    float = true,
    center = true,
    size = { 1024, 768 }
})

-- LocalSend sharing tool
hl.window_rule({
    match = { class = "Share|localsend" },
    float = true,
    center = true
})

-- Valve Steam Client interface rules
hl.window_rule({
    match = { class = "steam" },
    float = true,
    opacity = "1 1",
    idle_inhibit = "fullscreen"
})

-- Steam sub-window specific overrides
hl.window_rule({
    match = { class = "steam", title = "Steam" },
    center = true,
    size = { 1100, 700 }
})

hl.window_rule({
    match = { class = "steam", title = "Friends List" },
    size = { 460, 800 }
})
