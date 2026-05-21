-- -----------------------------------------------------
-- Window Management
-- -----------------------------------------------------

-- Graceful compositor logout via hyprshutdown paired with a clean UWSM stop sequence
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown --vt 2"), { desc = "Graceful Exit" })
-- Standard exit binding (e.g., Mod + Shift + M)
hl.bind(mainMod .. " + M", hl.dsp.exit(), { desc = "Exit Hyprland Session" })

-- [Window Mgmt]
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { desc = "Close window" })
hl.bind(mainMod .. " + G", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { desc = "Toggle fullscreen" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle floating" })

-- Move focus
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }), { desc = "Focus left" })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }), { desc = "Focus right" })
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }), { desc = "Focus up" })
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }), { desc = "Focus down" })

-- Move window
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }), { desc = "Move window left" })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }), { desc = "Move window right" })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }), { desc = "Move window up" })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }), { desc = "Move window down" })

-- Resize window (Passing explicit x and y values for the delta vector)
hl.bind(mainMod .. " + ALT + h", hl.dsp.window.resize({ x = -20, y = 0 }), { desc = "Resize left" })
hl.bind(mainMod .. " + ALT + l", hl.dsp.window.resize({ x = 20, y = 0 }), { desc = "Resize right" })
hl.bind(mainMod .. " + ALT + k", hl.dsp.window.resize({ x = 0, y = -20 }), { desc = "Resize up" })
hl.bind(mainMod .. " + ALT + j", hl.dsp.window.resize({ x = 0, y = 20 }), { desc = "Resize down" })

-- Mouse dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
