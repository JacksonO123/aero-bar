#!/bin/sh
# Installs the aero-bar login screen (greeter) for greetd. Run from the repository as root:
#
#   sudo ./greeter/install.sh
#
# It doesn't switch your display manager over; it prints how to do that (and how to go back).
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this as root: sudo $0" >&2
    exit 1
fi

REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST=/usr/local/share/aero-bar
STATE=/var/lib/aero-greeter
USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)

if ! getent passwd greeter >/dev/null; then
    echo "There is no 'greeter' user: install greetd first (pacman -S greetd)." >&2
    exit 1
fi

# a copy the greeter user can read (your home directory usually isn't readable to it)
echo "Copying the shell to $DEST"
rm -rf "$DEST.new"
cp -a "$REPO" "$DEST.new"
rm -rf "$DEST.new/.git"
rm -rf "$DEST"
mv "$DEST.new" "$DEST"
chmod -R a+rX "$DEST"

# where the greeter remembers the last session
install -d -o greeter -g greeter -m 700 "$STATE"

# your account picture, where the greeter can read it
if [ -n "${SUDO_USER:-}" ] && [ -s "$USER_HOME/.face" ] && [ ! -e "/var/lib/AccountsService/icons/$SUDO_USER" ]; then
    echo "Copying ~/.face to /var/lib/AccountsService/icons/$SUDO_USER"
    install -D -m 644 "$USER_HOME/.face" "/var/lib/AccountsService/icons/$SUDO_USER"
fi

# the greeter's compositor config, in the format your Hyprland reads
if [ -f "$USER_HOME/.config/hypr/hyprland.lua" ]; then
    COMPOSITOR_CONFIG="$DEST/greeter/hyprland.lua"
else
    COMPOSITOR_CONFIG="$DEST/greeter/hyprland.conf"
fi

if [ -f /etc/greetd/config.toml ] && [ ! -f /etc/greetd/config.toml.before-aero ]; then
    cp /etc/greetd/config.toml /etc/greetd/config.toml.before-aero
fi
mkdir -p /etc/greetd
cat >/etc/greetd/config.toml <<TOML
[terminal]
vt = 1

[default_session]
command = "Hyprland --config $COMPOSITOR_CONFIG"
user = "greeter"
TOML

cat <<DONE

Installed. greetd will run: Hyprland --config $COMPOSITOR_CONFIG

To switch from SDDM to it (then reboot):
  sudo systemctl disable sddm
  sudo systemctl enable greetd

If the login screen doesn't come up, switch to a text console (Ctrl+Alt+F2), log in and undo it:
  sudo systemctl disable greetd
  sudo systemctl enable sddm
  sudo reboot

Run this script again after changing the shell, to update the copy in $DEST.
DONE
