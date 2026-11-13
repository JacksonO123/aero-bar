//@ pragma IconTheme all-icons
//@ pragma UseQApplication

import Quickshell
import "modules/aero_bar"
import "modules/aero_bar/startmenu"
import "modules/aero_bar/theme"
import "modules/aero_bar/osd"
import "modules/aero_bar/notifications"
import "modules/aero_bar/lock"
import "modules/aero_bar/polkit"
import "modules/aero_bar/peek"
import "modules/aero_bar/switcher"

ShellRoot {
    Bar {}
    StartMenu {}
    ThemeDialog {}
    VolumeOsd {}
    NotificationPopups {}
    LockScreen {}
    AuthPrompt {}
    PeekOverlay {}
    SwitcherOverlay {}
}
