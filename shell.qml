//@ pragma IconTheme all-icons
//@ pragma UseQApplication

import Quickshell
import "modules/aero_bar"
import "modules/aero_bar/startmenu"
import "modules/aero_bar/theme"
import "modules/aero_bar/osd"

ShellRoot {
    Bar {}
    StartMenu {}
    ThemeDialog {}
    VolumeOsd {}
}
