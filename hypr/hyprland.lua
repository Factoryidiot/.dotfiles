-- Hyprland Lua Configuration Entry Point

-- Load core environmental variables early
require("modules.envs")

-- Load hardware and layout configurations
require("modules.monitors")
require("modules.input")

-- Load appearance and window rules
require("modules.looknfeel")
require("modules.windows")

-- Load interaction frameworks
require("modules.keybindings")

-- Execute startup applications
require("modules.autostart")
