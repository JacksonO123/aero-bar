pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property var date: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
