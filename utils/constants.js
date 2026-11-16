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

// the terminal the shell opens; change these values to switch terminals
const TERMINAL = {
    // binary to run
    cmd: "alacritty",
    // display name, used in the taskbar and frequent apps
    name: "Alacritty",
    // flag used to open in a given directory
    workingDirectoryFlag: ["--working-directory"],
    // prefix used to run a command inside the terminal
    commandPrefix: ["-e"],
    // window classes the taskbar matches against
    appIds: ["Alacritty"]
};

function terminalIn(dir) {
    return [TERMINAL.cmd, ...TERMINAL.workingDirectoryFlag, dir];
}

function terminalRunning(command) {
    return [TERMINAL.cmd, ...TERMINAL.commandPrefix, ...command];
}

const NETWORK_SETTINGS_CMD = ["nm-connection-editor"];
const BLUETOOTH_SETTINGS_CMD = ["blueman-manager"];

// a file name in /etc/pam.d
const LOCK_PAM_CONFIG = "login";

// default folder until one is chosen; a leading ~ is your home directory
const WALLPAPER_DIR = "~/Pictures/Wallpapers";

// gets the picture's path as its last argument
const WALLPAPER_SET_CMD = ["~/.local/bin/set-wallpaper"];

const ACCOUNT_PICTURES_DIR = "~/Pictures/account_pictures";

const NO_WORKSPACE = -99999;

const TIME_FORMAT = "h:mm AP";
const TIME_FORMAT_SECONDS = "h:mm:ss AP";

const WALLPAPER_CMD = "/home/jotto/scripts/bin/wallpaper";
