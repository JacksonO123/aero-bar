import QtQuick

// Aero's two-tone gloss: a vertical gradient with a hard step across the middle. `colors` are
// the four stops (top, just above the step, just below it, bottom); `split` and `splitEnd` place
// the step.
Gradient {
    id: root

    property var colors: ["transparent", "transparent", "transparent", "transparent"]
    property real split: 0.5
    property real splitEnd: 0.51

    GradientStop {
        position: 0
        color: root.colors[0]
    }
    GradientStop {
        position: root.split
        color: root.colors[1]
    }
    GradientStop {
        position: root.splitEnd
        color: root.colors[2]
    }
    GradientStop {
        position: 1
        color: root.colors[3]
    }
}
