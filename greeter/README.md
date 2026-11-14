# Login screen (greeter)

The Windows 7 logon screen for signing in, built from the same parts as the lock screen. It
replaces SDDM: [greetd](https://sr.ht/~kennylevinsen/greetd/) starts a small Hyprland as the
`greeter` user, which runs this Quickshell config (`qs -p .../greeter.qml`). After you sign in it
shows "Welcome", hands the session over to greetd and exits.

- More than one account: pick yours from the tiles ("Switch User" goes back).
- One account: straight to its password.
- The desktop session to start is bottom right, next to the power button (the last one used is
  remembered; Hyprland otherwise). Sessions come from `/usr/share/wayland-sessions`.
- Account pictures come from `/var/lib/AccountsService/icons/<user>` (the greeter can't read your
  home directory, so `~/.face` is only used if it's readable). `install.sh` copies your `~/.face`
  there if that's missing.

## Install

```sh
sudo pacman -S greetd                 # or your distro's package
sudo ./greeter/install.sh             # from this repository
sudo systemctl disable sddm
sudo systemctl enable greetd          # then reboot
```

`install.sh` copies the shell to `/usr/local/share/aero-bar` (readable by the greeter), creates
`/var/lib/aero-greeter` for its state, and writes `/etc/greetd/config.toml` (the old one is kept as
`config.toml.before-aero`). It picks `hyprland.lua` or `hyprland.conf` depending on which kind of
config your own Hyprland uses. Run it again after changing the shell.

If the login screen doesn't come up, switch to a text console (Ctrl+Alt+F2), log in and go back:

```sh
sudo systemctl disable greetd
sudo systemctl enable sddm
sudo reboot
```

To try it without rebooting, from a TTY: `sudo systemctl start greetd`.
