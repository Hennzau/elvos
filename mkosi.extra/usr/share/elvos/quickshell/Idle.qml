import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property int dimSeconds: 30
    property int sleepSeconds: 300
    property int dimPercent: 10
    property int restorePercent: -1

    Process {
        id: runner
    }

    function brightness(percent) {
        runner.command = ["brightnessctl", "set", percent + "%"];
        runner.startDetached();
    }

    Process {
        id: probe

        command: ["brightnessctl", "-m"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",");
                if (parts.length < 4)
                    return;

                const current = parseInt(parts[3]);

                root.restorePercent = current;
                root.brightness(root.dimPercent);
            }
        }
    }

    IdleMonitor {
        timeout: root.dimSeconds

        respectInhibitors: true

        onIsIdleChanged: {
            if (isIdle) {
                probe.running = true;
                return;
            }

            if (root.restorePercent > 0) {
                root.brightness(root.restorePercent);
                root.restorePercent = -1;
            }
        }
    }

    Process {
        id: sleeper
    }

    IdleMonitor {
        timeout: root.sleepSeconds
        respectInhibitors: true

        onIsIdleChanged: {
            if (!isIdle)
                return;

            sleeper.command = ["sh", "-c", "elvos-lock & sleep 0.3; systemctl suspend"];
            sleeper.startDetached();
        }
    }
}
