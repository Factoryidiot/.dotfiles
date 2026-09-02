-- -----------------------------------------------------
-- Hardware Keys & Media Control (Native Quickshell OSD)
-- -----------------------------------------------------

-- [Hardware]
-- Volume control
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("quickshell ipc call osd volume +5"), { repeatable = true, locked = true, desc = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("quickshell ipc call osd volume -5"), { repeatable = true, locked = true, desc = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("quickshell ipc call osd volumeMute"), { repeatable = true, locked = true, desc = "Mute" })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd("quickshell ipc call osd volume +1"), { repeatable = true, locked = true, desc = "Volume up precise" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd("quickshell ipc call osd volume -1"), { repeatable = true, locked = true, desc = "Volume down precise" })

-- Microphone control
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("quickshell ipc call osd micMute"), { repeatable = true, locked = true, desc = "Mute microphone" })

-- Brightness control
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("quickshell ipc call osd brightness +5"), { repeatable = true, locked = true, desc = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("quickshell ipc call osd brightness -5"), { repeatable = true, locked = true, desc = "Brightness down" })
hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd("quickshell ipc call osd brightness +1"), { repeatable = true, locked = true, desc = "Brightness up precise" })
hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd("quickshell ipc call osd brightness -1"), { repeatable = true, locked = true, desc = "Brightness down precise" })

-- Media player control
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("quickshell ipc call osd media next"), { locked = true, desc = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("quickshell ipc call osd media play-pause"), { locked = true, desc = "Pause" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("quickshell ipc call osd media play-pause"), { locked = true, desc = "Play" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("quickshell ipc call osd media previous"), { locked = true, desc = "Previous track" })

-- Caps Lock (accurate LED hardware state)
hl.bind("CAPS + Caps_Lock", hl.dsp.exec_cmd("quickshell ipc call osd capslock"), { locked = true, desc = "Caps lock" })
