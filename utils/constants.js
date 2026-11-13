.pragma library

const BAR_HEIGHT = 42;
const ICON_BUTTON_WIDTH = 62;
// tall enough for the calendar's year view; the mask keeps the unused area click-through
const FULL_ALLOCATED_HEIGHT = 600;

// how long the pointer has to rest on the workspace buttons before the overview opens (ms)
const OVERVIEW_HOVER_DELAY = 800;
// launched by right-clicking the volume module and by the "Mixer" link in its flyout
const VOLUME_MIXER_CMD = ["pavucontrol"];
// prefix for launching terminal apps (Terminal=true desktop entries) from the start menu
const TERMINAL_CMD = ["alacritty", "-e"];
// how long the volume pop-up stays after the last change (ms)
const OSD_TIMEOUT = 1600;
