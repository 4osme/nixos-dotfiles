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
hl.layout.register("dotfiles-refresh", { recalculate = function() end })

-- Sunshine streaming profiles (manual `sunshine-session start` / `stop`).
-- The manual helper creates the HEADLESS-1 virtual output (FullHD); while a
-- stream profile marker exists this config moves that output to 0x0 and
-- disables the physical HDMI outputs. `sunshine-session stop` removes the
-- marker and the virtual output; the normal layout then comes back from Dux
-- Shell's `~/.config/hypr/dms/outputs.lua` (the only monitor source: DMS /
-- nwg-displays wrote it, and `hyprctl reload` re-applies it).

local sunshineRuntime = os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000"
local sunshineProfile = io.open(sunshineRuntime .. "/sunshine-hypr-display/1080p.active", "r")
local sunshineNative = io.open(sunshineRuntime .. "/sunshine-hypr-display/native.active", "r")
-- Session scope marker (written by `sunshine-session start`). While it exists
-- the physical outputs stay disabled, no matter whether a client is
-- connected: rendering to the 4K panel costs GPU/CPU and makes the stream
-- heavier.
local sunshineSession = io.open(sunshineRuntime .. "/sunshine-hypr-display/session.active", "r")

-- capture/output_name in the (unmanaged) Sunshine config are written by
-- `sunshine-session`. Read them so the streaming layout follows output_name
-- instead of hardcoding the virtual output.
local function sunshineConfig(key)
    local path = (os.getenv("HOME") or "") .. "/.config/sunshine/sunshine.conf"
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local value = nil
    for line in file:lines() do
        local match = line:match("^%s*" .. key .. "%s*=%s*(%S+)")
        if match then
            value = match
        end
    end
    file:close()
    return value
end

-- Disable every output except the one Sunshine captures. The live monitor list
-- covers outputs that DMS named differently (or a hot-plugged display); the
-- fixed list stays as a fallback for the first config load, when the Lua
-- monitor list can still be empty.
local function disablePhysicalOutputs(output)
    local seen = {}
    local ok, list = pcall(function()
        return hl.get_monitors and hl.get_monitors({ all = true }) or {}
    end)
    if ok and type(list) == "table" then
        for _, monitor in ipairs(list) do
            local name = monitor.name
            if name and name ~= output and not name:find("^HEADLESS%-") then
                hl.monitor({ output = name, disabled = true })
                seen[name] = true
            end
        end
    end
    for _, name in ipairs({ "HDMI-A-1", "HDMI-A-2" }) do
        if name ~= output and not seen[name] then
            hl.monitor({ output = name, disabled = true })
        end
    end
end

local function applySunshineLayout(mode)
    local output = sunshineConfig("output_name") or "HEADLESS-1"
    if output == "" then
        output = "HEADLESS-1"
    end
    -- A headless output is created at 1920x1080@60; pin that mode explicitly so
    -- the stream does not inherit a stale "preferred" from another profile.
    if output:find("^HEADLESS%-") then
        mode = "1920x1080@60"
    end
    hl.monitor({ output = output, mode = mode, position = "0x0", scale = 1.0, transform = 0 })
    disablePhysicalOutputs(output)
end

if sunshineProfile then
    sunshineProfile:close()
    applySunshineLayout("1920x1080@60")
    for i = 1, 8 do
        hl.workspace_rule({ workspace = tostring(i), layout = "dwindle" })
    end
    -- Refresh existing workspaces after applying the temporary rules.
    hl.layout.register("dotfiles-stream-refresh", { recalculate = function() end })
elseif sunshineNative then
    sunshineNative:close()
    -- Native streaming: keep the resolution but disable the other outputs and
    -- pin the captured output to the origin. This keeps absolute mouse input
    -- exact even when Sunshine could not query the Wayland monitor layout
    -- (single monitor at 0x0 means the raw KMS offsets are already correct).
    applySunshineLayout("preferred")
else
    -- Session scope: Sunshine captures the virtual output, so the physical
    -- outputs stay disabled (the 4K panel would cost GPU/CPU and make the
    -- stream heavier). A client connect/disconnect must not bring them back.
    if sunshineSession then
        sunshineSession:close()
        applySunshineLayout("preferred")
    else
        -- No session and no client: keep the virtual output alive (Sunshine's
        -- encoder probe needs a live output) and park it far to the right so
        -- Dux Shell's outputs.lua keeps the physical layout. This also catches a
        -- HEADLESS-* output left behind by a crashed session.
        local output = sunshineConfig("output_name") or "HEADLESS-1"
        if output:find("^HEADLESS%-") then
            hl.monitor({ output = output, mode = "1920x1080@60", position = "10000x0", scale = 1.0, transform = 0 })
        end
    end
end

-- Also handles a stream started at SDDM before this Hyprland session exists.
-- The helper takes a per-instance lock, so config reloads do not duplicate it.
local sunshineDisplayWatcher = 'python3 "$HOME/.config/sunshine/hypr-stream-display.py" watch'
hl.on("hyprland.start", function()
    hl.exec_cmd(sunshineDisplayWatcher)
end)
-- Start it on a reload of an already running session as well.
hl.exec_cmd(sunshineDisplayWatcher)