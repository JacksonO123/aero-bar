//@ pragma IconTheme all-icons
//@ pragma UseQApplication

import Quickshell
import "modules/aero_bar"
import "modules/aero_bar/startmenu"
import "modules/aero_bar/theme"
import "modules/aero_bar/osd"
import "modules/aero_bar/notifications"
import "modules/aero_bar/lock"

ShellRoot {
    Bar {}
    StartMenu {}
    ThemeDialog {}
    VolumeOsd {}
    NotificationPopups {}
    LockScreen {}
}
