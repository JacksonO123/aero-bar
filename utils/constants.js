.pragma library

const BAR_HEIGHT = 42;
const ICON_BUTTON_WIDTH = 62;

// fits the calendar's year view; the mask keeps the unused area click-through
const FULL_ALLOCATED_HEIGHT = 600;

const OVERVIEW_HOVER_DELAY = 800;

const THUMBNAIL_DELAY = 400;
const PEEK_DELAY = 500;

const OSD_TIMEOUT = 1600;

// used when a notification doesn't set its own timeout
const NOTIFICATION_TIMEOUT = 6000;
const MAX_NOTIFICATION_POPUPS = 3;

const VOLUME_MIXER_CMD = ["pavucontrol"];

// prefix for Terminal=true apps; their command is appended
const TERMINAL_CMD = ["alacritty", "-e"];

const NETWORK_SETTINGS_CMD = ["nm-connection-editor"];
const BLUETOOTH_SETTINGS_CMD = ["blueman-manager"];

// a file name in /etc/pam.d
const LOCK_PAM_CONFIG = "login";

// default folder until one is chosen; a leading ~ is your home directory
const WALLPAPER_DIR = "~/Pictures/Wallpapers";

// gets the picture's path as its last argument
const WALLPAPER_SET_CMD = ["~/.local/bin/set-wallpaper"];

const ACCOUNT_PICTURES_DIR = "~/Pictures/Account Pictures";

const NO_WORKSPACE = -99999;

const TIME_FORMAT = "h:mm AP";
const TIME_FORMAT_SECONDS = "h:mm:ss AP";
