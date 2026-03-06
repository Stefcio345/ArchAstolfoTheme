import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire

PanelWindow {
    id: popup

    visible: false

    layer: "overlay"   // ensures it floats above bar

    anchors {
        top: true
        right: true
    }

    margins {
        top: 44     // below your 36px bar
        right: 20
    }

    implicitWidth: 280
    implicitHeight: 180

    property var defaultSink: Pipewire.defaultAudioSink ?? null

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "#181825ee"
        border.color: "#f38ba8"
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Text {
                text: "Audio Mixer"
                color: "#f5c2e7"
                font.pixelSize: 15
                font.bold: true
            }

            Slider {
                Layout.fillWidth: true
                from: 0
                to: 1.5
                value: defaultSink ? defaultSink.volume : 0

                onMoved: {
                    if (defaultSink)
                        defaultSink.volume = value
                }
            }

            Button {
                text: defaultSink && defaultSink.muted ? "Unmute" : "Mute"

                onClicked: {
                    if (defaultSink)
                        defaultSink.muted = !defaultSink.muted
                }
            }
        }
    }
}