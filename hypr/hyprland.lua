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

-- -----------------------------------------------------
-- Optional Host-Specific & Local Overrides
-- -----------------------------------------------------
-- Attempt to load hostname-specific configuration (e.g. hypr/modules/hosts/<hostname>.lua)
local hostname_pipe = io.popen("hostname 2>/dev/null")
if hostname_pipe then
    local host = hostname_pipe:read("*a")
    hostname_pipe:close()
    if host then
        host = host:gsub("%s+", "")
        if host ~= "" then
            pcall(require, "modules.hosts." .. host)
        end
    end
end

-- Attempt to load uncommitted local overrides (hypr/modules/local.lua)
pcall(require, "modules.local")

