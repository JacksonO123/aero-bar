.pragma library

// ---- layout -------------------------------------------------------------------------------

const BAR_HEIGHT = 42;
const ICON_BUTTON_WIDTH = 62;

// tall enough for the calendar's year view; the mask keeps the unused area click-through
const FULL_ALLOCATED_HEIGHT = 600;

// ---- timing (ms) ----------------------------------------------------------------------------

// how long the pointer has to rest on the workspace buttons before the overview opens
const OVERVIEW_HOVER_DELAY = 800;

// taskbar thumbnails: hover time before they first appear, and before Aero Peek kicks in
const THUMBNAIL_DELAY = 400;
const PEEK_DELAY = 500;

// how long the volume pop-up stays after the last change
const OSD_TIMEOUT = 1600;

// notification balloons: how long one stays when the app doesn't say, and how many stack
const NOTIFICATION_TIMEOUT = 6000;
const MAX_NOTIFICATION_POPUPS = 3;

// ---- programs the shell runs ----------------------------------------------------------------

// launched by right-clicking the volume module and by the "Mixer" link in its flyout
const VOLUME_MIXER_CMD = ["pavucontrol"];

// prefix for launching terminal apps (Terminal=true desktop entries) from the start menu
const TERMINAL_CMD = ["alacritty", "-e"];

// opened by the links at the bottom of the network and Bluetooth flyouts
const NETWORK_SETTINGS_CMD = ["nm-connection-editor"];
const BLUETOOTH_SETTINGS_CMD = ["blueman-manager"];

// PAM service (a file in /etc/pam.d) the lock screen checks passwords with
const LOCK_PAM_CONFIG = "login";

// ---- desktop background ---------------------------------------------------------------------

// where the Desktop Background picker looks for pictures until you choose another folder
// (a leading ~ is your home directory)
const WALLPAPER_DIR = "~/Pictures/Wallpapers";

// your script that sets the wallpaper; it gets the picture's path as its last argument
const WALLPAPER_SET_CMD = ["~/.local/bin/set-wallpaper"];

// ---- account picture ------------------------------------------------------------------------

// the pictures "Change Your Picture" offers (put the Windows 7 account pictures here: they're in
// C:\ProgramData\Microsoft\User Account Pictures\Default Pictures on a Windows 7 PC)
const ACCOUNT_PICTURES_DIR = "~/Pictures/Account Pictures";

// ---- other ----------------------------------------------------------------------------------

// "no workspace" for workspace ids (hover / highlight state)
const NO_WORKSPACE = -99999;

// the clock's time format (taskbar, lock screen, notification times)
const TIME_FORMAT = "h:mm AP";
const TIME_FORMAT_SECONDS = "h:mm:ss AP";
