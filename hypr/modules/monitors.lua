-- -----------------------------------------------------
-- Monitor Configuration
-- -----------------------------------------------------

-- HDMI-A-1 at native 1440p, positioned at the origin (0x0)
hl.monitor({
    output = "HDMI-A-1",
    mode = "2560x1440@100",
    position = "0x0",
    scale = 1
})

-- Laptop display positioned exactly to the right of the HDMI monitor (2560x0)
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144",
    position = "2560x0",
    scale = 1
})
