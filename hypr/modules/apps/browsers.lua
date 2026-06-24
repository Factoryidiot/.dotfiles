-- -----------------------------------------------------
-- Browser Layouts, Webapps, and Security Rules
-- -----------------------------------------------------

-- Security hardening & layout for Bitwarden
hl.window_rule({
  match = { class = "^(Bitwarden)$" },
  tag = "+floating-window",
  no_screen_share = true
})

-- Browser categorization rules via regex matching
hl.window_rule({
    match = { class = "^brave|(google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium" },
    tag = "+chromium-based-browser"
})

hl.window_rule({
    match = { class = "[fF]irefox|zen|librewolf" },
    tag = "+firefox-based-browser"
})

-- Structural layout behaviors
hl.window_rule({
    match = { tag = "chromium-based-browser" },
    tile = true
})

-- Rendering Opacity controls (space-separated strings, no commas)
hl.window_rule({
    match = { tag = "chromium-based-browser" },
    opacity = "1 0.97"
})

hl.window_rule({
    match = { tag = "firefox-based-browser" },
    opacity = "1 0.97"
})

-- Full bypass matching for video and collaboration workflows
hl.window_rule({
    match = { initial_title = "((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)" },
    opacity = "1.0 1.0"
})
