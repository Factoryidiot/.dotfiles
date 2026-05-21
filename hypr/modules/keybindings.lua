-- -----------------------------------------------------
-- Key Bindings Router
-- -----------------------------------------------------

-- Declare globally so nested sub-modules can see it without redeclaring
_G.mainMod = "SUPER"

-- Load our broken-out keybinding groups
require("modules.bindings.launchers")
require("modules.bindings.window_mgmt")
require("modules.bindings.workspaces")
require("modules.bindings.hardware")
