-- -----------------------------------------------------
-- Workspace Routing Loops
-- -----------------------------------------------------

-- [Workspaces]
-- Using a standard Lua loop to cleanly bind keys 1 through 9
for i = 1, 9 do
    local ws = tostring(i)
    hl.bind(mainMod .. " + " .. ws, hl.dsp.focus({ workspace = ws }), { desc = "Go to workspace " .. ws })
    hl.bind(mainMod .. " + SHIFT + " .. ws, hl.dsp.window.move({ workspace = ws }), { desc = "Move window to workspace " .. ws })
end

-- Handle workspace 10 mapped to key 0
hl.bind(mainMod .. " + " .. "0", hl.dsp.focus({ workspace = 10 }), { desc = "Go to workspace 10" })
hl.bind(mainMod .. " + SHIFT + " .. "0", hl.dsp.window.move({ workspace = 10 }), { desc = "Move window to workspace 10" })

-- Scroll through existing workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })
