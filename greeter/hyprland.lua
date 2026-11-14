-- The login screen's own small Hyprland, which greetd starts as the "greeter" user. It runs the
-- Quickshell greeter and exits once the greeter has handed over to the session you signed in to.
-- (For Hyprland with a Lua config; hyprland.conf is the same for the classic config format.)

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- the greeter remembers the last session here (install.sh creates it)
hl.env("XDG_STATE_HOME", "/var/lib/aero-greeter")
hl.env("XCURSOR_SIZE", "24")

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
    -- the greeter fades itself in
    animations = {
        enabled = false,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p /usr/local/share/aero-bar/greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)
