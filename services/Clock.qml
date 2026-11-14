pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property var date: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // its timer doesn't count time asleep: a tick far later than 5 s means a resume
    property double lastTick: Date.now()

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            const now = Date.now();
            if (now - root.lastTick > 15000) {
                clock.enabled = false;
                clock.enabled = true;
            }
            root.lastTick = now;
        }
    }
}
