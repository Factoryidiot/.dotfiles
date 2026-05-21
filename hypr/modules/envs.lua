-- -----------------------------------------------------
-- Environment variables
-- -----------------------------------------------------

-- Cursor size
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Expanding $HOME and existing variables in Lua is cleaner with os.getenv
local home = os.getenv("HOME") or ""
local existing_xdg_dirs = os.getenv("XDG_DATA_DIRS") or ""
hl.env("XDG_DATA_DIRS", home .. "/.local/share/web-apps:" .. existing_xdg_dirs)

-- Force all apps to use Wayland
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Allow better support for screen sharing (Google Meet, Discord, etc).
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Use XCompose file
hl.env("XCOMPOSEFILE", home .. "/.XCompose")

-- -----------------------------------------------------
-- System Config Blocks
-- -----------------------------------------------------
-- Nested configuration blocks like xwayland {} map directly to Lua tables 
-- passed into the hl.config() function.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    -- Commented out but preserved for your reference:
    -- ecosystem = {
    --     no_update_news = true,
    -- },
})
