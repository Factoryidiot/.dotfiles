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

-- -----------------------------------------------------
-- Dynamic Multi-GPU & Hardware Auto-Detection
-- -----------------------------------------------------
local function configure_gpu()
    local primary = nil
    local secondaries = {}
    local has_nvidia = false

    -- Check if NVIDIA driver module is loaded
    local nvidia_driver_dir = io.open("/sys/bus/pci/drivers/nvidia", "r")
    if nvidia_driver_dir then
        has_nvidia = true
        nvidia_driver_dir:close()
    end

    local p = io.popen("ls -d /sys/class/drm/card[0-9] /sys/class/drm/card[0-9][0-9] 2>/dev/null")
    if p then
        for path in p:lines() do
            local card_name = path:match("([^/]+)$")
            if card_name then
                local boot_file = io.open(path .. "/device/boot_vga", "r")
                local is_boot = boot_file and (boot_file:read("*a"):find("1") ~= nil)
                if boot_file then boot_file:close() end

                local dev_path = "/dev/dri/" .. card_name

                if is_boot then
                    primary = dev_path
                else
                    table.insert(secondaries, dev_path)
                end
            end
        end
        p:close()
    end

    -- If no primary was explicitly marked by boot_vga, default to the first discovered card
    if not primary and #secondaries > 0 then
        primary = table.remove(secondaries, 1)
    end

    -- If multiple GPUs exist, set AQ_DRM_DEVICES with primary boot GPU first
    if primary and #secondaries > 0 then
        local devices = primary
        for _, sec in ipairs(secondaries) do
            devices = devices .. ":" .. sec
        end
        hl.env("AQ_DRM_DEVICES", devices)
    end

    -- Configure NVIDIA specific environment variables only when NVIDIA hardware is active
    if has_nvidia then
        hl.env("LIBVA_DRIVER_NAME", "nvidia")
        hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
        hl.env("GBM_BACKEND", "nvidia-drm")
        hl.env("NVD_BACKEND", "direct")
    end
end

configure_gpu()


-- Force all apps to use Wayland
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
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
