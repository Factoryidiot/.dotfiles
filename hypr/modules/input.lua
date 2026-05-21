-- -----------------------------------------------------
-- Input Configuration
-- -----------------------------------------------------

hl.config({
    input = {
        kb_layout = "us",
        -- kb_model and kb_rules left blank natively
        kb_model = "",
        kb_rules = "",

        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        
        -- Float mapping
        sensitivity = 0.0,

        accel_profile = "flat",
        force_no_accel = true,

        touchpad = {
            natural_scroll = false,
            scroll_factor = 0.5,
        },
    },

    gestures = {},

    -- Preserved per-device block example syntax for reference
    -- device = {
    --     name = "YOUR_DEVICE_NAME",
    --     sensitivity = 0,
    -- },
})
