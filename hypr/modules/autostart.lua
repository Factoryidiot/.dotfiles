-- -----------------------------------------------------
-- Autostart Applications (Hyprland v0.55+ Lua API)
-- -----------------------------------------------------

hl.on("hyprland.start", function()
    -- Base session environment initialization
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")

    -- Background apps and daemons managed by UWSM
    hl.exec_cmd("uwsm-app -- elephant")
    hl.exec_cmd("uwsm-app -- hypridle")
    hl.exec_cmd("uwsm-app -- mako")
    hl.exec_cmd("uwsm-app -- swayosd-watchdog")
    hl.exec_cmd("uwsm-app -- walker --gapplication-service")
    hl.exec_cmd("uwsm-app -- waybar")
    hl.exec_cmd("uwsm-app -- wl-paste --watch cliphist store")
end)
