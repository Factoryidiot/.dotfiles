-- -----------------------------------------------------
-- Hardware Keys & Media Control
-- -----------------------------------------------------

-- Dynamic OSD client helper
local osdclient = [[swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"]]

-- [Hardware]
-- Volume control
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume raise"), { repeatable = true, locked = true, desc = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume lower"), { repeatable = true, locked = true, desc = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(osdclient .. " --output-volume mute-toggle"), { repeatable = true, locked = true, desc = "Mute" })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume +1"), { repeatable = true, locked = true, desc = "Volume up precise" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume -1"), { repeatable = true, locked = true, desc = "Volume down precise" })

-- Microphone control
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(osdclient .. " --input-volume mute-toggle"), { repeatable = true, locked = true, desc = "Mute microphone" })

-- Brightness control
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osdclient .. " --brightness raise"), { repeatable = true, locked = true, desc = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osdclient .. " --brightness lower"), { repeatable = true, locked = true, desc = "Brightness down" })
hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd(osdclient .. " --brightness +1"), { repeatable = true, locked = true, desc = "Brightness up precise" })
hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd(osdclient .. " --brightness -1"), { repeatable = true, locked = true, desc = "Brightness down precise" })

-- Media player control
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(osdclient .. " --playerctl next"), { locked = true, desc = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(osdclient .. " --playerctl play-pause"), { locked = true, desc = "Pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(osdclient .. " --playerctl play-pause"), { locked = true, desc = "Play" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(osdclient .. " --playerctl previous"), { locked = true, desc = "Previous track" })

-- Caps Lock (using your verified working pattern)
hl.bind("CAPS + Caps_Lock", hl.dsp.exec_cmd(osdclient .. " --caps-lock"), { locked = true, desc = "Caps lock" })
