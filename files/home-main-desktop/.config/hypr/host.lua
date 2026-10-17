-- main-desktop host extras — Home Manager managed
-- (files/home-main-desktop/.config/hypr/host.lua).
--
-- Moved out of the old fedora-hyprtomic local.conf: workspace assignments,
-- per-workspace layouts and the Sunshine streaming profiles. Generic
-- keybinds/settings live in hyprland.lua; ~/.config/hypr/local.conf remains
-- the unmanaged debug escape hatch and is loaded after this file.

-- Cider (Apple Music client): keep it on the second display.
hl.window_rule({
    name = "cider-subdisplay",
    match = {
        class = "cider",
    },
    workspace = "9",
})

-- X (Twitter) as a Chrome app: workspace 10.
hl.window_rule({
    name = "x-subdisplay",
    match = {
        class         = "^chrome-.*-Default$",
        initial_title = "^(X|X.* / X)$",
    },
    workspace = "10",
})

-- quadgrid on the main-monitor workspaces (1-8).
for i = 1, 8 do
    hl.workspace_rule({ workspace = tostring(i), layout = "lua:quadgrid" })
end

-- Registering a layout algorithm is what makes Hyprland re-evaluate existing
-- workspaces; a workspace rule alone does not trigger it. This no-op
-- registration (after the rules above) makes them apply on `hyprctl reload`.
hl.layout.register("hyprtomic-refresh", { recalculate = function() end })

-- Sunshine: temporary fixed 1080p30 / dwindle profile while streaming.
-- Persistent normal mode. Keep this in sync with monitors.lua:
-- HDMI-A-1 (4K) sits to the right of the rotated HDMI-A-2.
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "648x0", scale = 1.0, transform = 0 })

local sunshineRuntime = os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000"
local sunshineProfile = io.open(sunshineRuntime .. "/sunshine-hypr-display/1080p.active", "r")
local sunshineNative = io.open(sunshineRuntime .. "/sunshine-hypr-display/native.active", "r")
if sunshineProfile then
    sunshineProfile:close()
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1.0, transform = 0 })
    hl.monitor({ output = "HDMI-A-2", disabled = true })
    for i = 1, 8 do
        hl.workspace_rule({ workspace = tostring(i), layout = "dwindle" })
    end
    -- Refresh existing workspaces after applying the temporary rules.
    hl.layout.register("hyprtomic-stream-refresh", { recalculate = function() end })
elseif sunshineNative then
    sunshineNative:close()
    -- Native streaming: keep the resolution but disable the other outputs and
    -- pin HDMI-A-1 to the origin. This keeps absolute mouse input exact even
    -- when Sunshine could not query the Wayland monitor layout (single monitor
    -- at 0x0 means the raw KMS offsets are already correct).
    hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0", scale = 1.0, transform = 0 })
    hl.monitor({ output = "HDMI-A-2", disabled = true })
end

-- Also handles a stream started at SDDM before this Hyprland session exists.
-- The helper takes a per-instance lock, so config reloads do not duplicate it.
local sunshineDisplayWatcher = 'python3 "$HOME/.config/sunshine/hypr-stream-display.py" watch'
hl.on("hyprland.start", function()
    hl.exec_cmd(sunshineDisplayWatcher)
end)
-- Start it on a reload of an already running session as well.
hl.exec_cmd(sunshineDisplayWatcher)
