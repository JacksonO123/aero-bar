-- greeter's Hyprland, run by greetd (Lua; hyprland.conf for the classic format)

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- greeter state (last session); install.sh creates it
hl.env("XDG_STATE_HOME", "/var/lib/aero-greeter")
hl.env("XCURSOR_SIZE", "24")

hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
    },
    animations = {
        enabled = false,
    },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p /usr/local/share/aero-bar/greeter; hyprctl dispatch 'hl.dsp.exit()'")
end)
