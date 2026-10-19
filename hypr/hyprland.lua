-- Hyprland 0.55+ Lua configuration
-- https://wiki.hypr.land/Configuring/Start/
--
-- hyprsplit must be available as a Lua module, for example at:
-- ~/.config/hypr/hyprsplit/init.lua

local home = assert(os.getenv("HOME"), "HOME must be set")
local xdgConfigHome = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
package.path = xdgConfigHome .. "/hypr/lib/?/init.lua;" .. package.path
local hs = require("hyprsplit")
local host = {}
local localConfig = xdgConfigHome .. "/hypr/local.lua"
local localFile = io.open(localConfig, "r")
if localFile then
    localFile:close()
    host = dofile(localConfig)
end

--------------------------------------------------
-- DARK-BLACK ASTOLFO FEMBOY THEME
--------------------------------------------------
-- bg0     #0f0f12
-- bg1     #1a1b1f
-- surface #23242a
-- edge    #2e2f36
-- muted   #3a3a40
-- text    #e4e4e7
-- accent  #f38ba8
-- accent2 #ffb3c6

----------------
-- MONITORS
----------------

for _, monitor in ipairs(host.monitors or {
    { output = "", mode = "preferred", position = "auto", scale = 1 },
}) do
    hl.monitor(monitor)
end

----------------
-- HYPRSPLIT
----------------

hs.config({
    persistent_workspaces = false,
    num_workspaces = 10,
})

----------------
-- PROGRAMS
----------------

local terminal = "kitty"
local fileManager = '"' .. xdgConfigHome .. '/scripts/file-manager.sh"'
local menu = "walker"
local searchEngine = "firefox" -- Kept for use by additional config files.

----------------
-- AUTOSTART
----------------

hl.on("hyprland.start", function()
    hl.exec_cmd("env LC_TIME=ja_JP.UTF-8 waybar")
    hl.exec_cmd("spotify-launcher")
    hl.exec_cmd("command -v xfsettingsd >/dev/null 2>&1 && xfsettingsd")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("openrgb -p default")
    hl.exec_cmd("elephant")
    hl.exec_cmd("walker --gapplication-service")

    -- Dark theme
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")

	-- Thunar
	hl.exec_cmd("systemctl --user import-environment XDG_CONFIG_HOME ZDOTDIR PATH WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP")

    -- Authentication
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Notifications
    hl.exec_cmd("mako")
end)

----------------
-- ENVIRONMENT
----------------

hl.env("HYPRCURSOR_THEME", xdgConfigHome .. "/icons/rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "22")
hl.env("XDG_CONFIG_HOME", xdgConfigHome)
for key, value in pairs(host.environment or {}) do
    hl.env(key, value)
end
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("CHROMIUM_FLAGS", "--force-dark-mode")

----------------
-- LOOK AND FEEL
----------------

hl.config({
    general = {
        gaps_in = 10,
        gaps_out = 20,
        border_size = 3,
        col = {
            active_border = {
                colors = { "rgba(f38ba8ee)", "rgba(ffb3c6ee)" },
                angle = 90,
            },
            inactive_border = "rgba(a37783ee)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 3,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 5,
            -- Hyprland 0.55 accepts values from 1 through 4.
            render_power = 4,
            color = "rgba(f38ba8ee)",
            sharp = false,
        },
        blur = {
            enabled = true,
            size = 4,
            passes = 3,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },

    input = {
        kb_layout = "pl",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },

    cursor = {
        -- The Lua config expects 0/1/2 here rather than a boolean.
        no_hardware_cursors = 0,
    },
})

----------------
-- ANIMATIONS
----------------

hl.curve("softOut", {
    type = "bezier",
    points = { { 0.05, 0.9 }, { 0.1, 1 } },
})

hl.curve("softInOut", {
    type = "bezier",
    points = { { 0.65, 0 }, { 0.35, 1 } },
})

hl.curve("overshoot", {
    type = "bezier",
    points = { { 0.34, 1.7 }, { 0.3, 1 } },
})

hl.curve("floaty", {
    type = "bezier",
    points = { { 0.23, 1 }, { 0.32, 1 } },
})

hl.animation({ leaf = "global", enabled = true, speed = 7, bezier = "default" })

-- Windows
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "floaty" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "overshoot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "softInOut", style = "popin 80%" })

-- Borders
hl.animation({ leaf = "border", enabled = true, speed = 7, bezier = "softOut" })

-- Fades
hl.animation({ leaf = "fadeIn", enabled = true, speed = 5, bezier = "softOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "softInOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "softOut" })

-- Layers
hl.animation({ leaf = "layers", enabled = true, speed = 7, bezier = "floaty", style = "popin 78%" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 7, bezier = "floaty", style = "popin 78%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 5, bezier = "floaty", style = "popin 78%" })

-- Workspaces
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "softInOut" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 7, bezier = "softInOut" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 7, bezier = "softInOut" })

----------------
-- DEVICES
----------------

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

----------------
-- KEYBINDINGS
----------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("walker -s clipboard"))
hl.bind("F1", hl.dsp.exec_cmd('test -x "' .. home .. '/Scripts/clicker.sh" && "' .. home .. '/Scripts/clicker.sh"'))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd(xdgConfigHome .. "/scripts/keyboardToggle.sh"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Steam Controller bindings
hl.bind(
    mainMod .. " + SHIFT + K",
    hl.dsp.exec_cmd(menu .. "; " .. xdgConfigHome .. "/scripts/keyboardToggle.sh")
)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch and move windows between hyprsplit workspaces.
for i = 1, 10 do
    local key = i % 10 -- Workspace 10 maps to key 0.

    hl.bind(mainMod .. " + " .. key, hs.dsp.focus({ workspace = i }))
    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hs.dsp.window.move({ workspace = i, follow = false })
    )
end

-- Scroll through existing workspaces.
hl.bind(mainMod .. " + mouse_down", hs.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + mouse_up", hs.dsp.focus({ workspace = "r-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume and brightness keys.
local repeatWhenLocked = { locked = true, repeating = true }

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), repeatWhenLocked)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), repeatWhenLocked)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), repeatWhenLocked)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), repeatWhenLocked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), repeatWhenLocked)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), repeatWhenLocked)

-- Media controls.
local whenLocked = { locked = true }

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), whenLocked)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), whenLocked)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), whenLocked)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), whenLocked)

-- Screenshots, screen recording and color picker.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('"' .. xdgConfigHome .. '/scripts/screenshot.sh"'))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd('"' .. xdgConfigHome .. '/scripts/ScreenRecord.sh"'))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))

----------------
-- WINDOW RULES
----------------

hl.window_rule({
    name = "code-modal-under-cursor",
    match = {
        class = "^(Code)$",
        modal = true,
    },
    float = true,
    animation = "popin",
    move = "(cursor_x-(window_w/2)) (cursor_y-(window_h/2))",
})

hl.window_rule({
    name = "thunar-modal-under-cursor",
    match = {
        class = "^thunar$",
        title = "^Rename.*",
    },
    float = true,
    animation = "popin",
    move = "(cursor_x-(window_w*0.5)) (cursor_y-(window_h*0.5))",
})

hl.window_rule({
    name = "floating-pavucontrol",
    match = {
        class = "^(org\\.pulseaudio\\.pavucontrol)$",
    },
    float = true,
    animation = "popin",
    move = "(cursor_x-(window_w/2)) (cursor_y-window_h)",
})

----------------
-- LAYER RULES
----------------

hl.layer_rule({
    name = "jushot-no-animation",
    match = { namespace = "^(jushot)$" },
    no_anim = true,
})

hl.layer_rule({
    name = "selection-no-animation",
    match = { namespace = "^selection$" },
    no_anim = true,
})

hl.layer_rule({
    name = "hyprpicker-no-animation",
    match = { namespace = "^hyprpicker$" },
    no_anim = true,
})
