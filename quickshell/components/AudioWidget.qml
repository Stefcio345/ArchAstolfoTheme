import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root
    width: 42
    height: 28

    property var defaultSink: Pipewire.defaultAudioSink ?? null

    Rectangle {
        id: button
        anchors.fill: parent
        radius: 12
        color: "#313244"
        border.color: hovered ? "#f5c2e7" : "#f38ba8"
        border.width: 2

        property bool hovered: false

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: button.hovered = true
            onExited: button.hovered = false

            onClicked: {
                audioPopup.visible = !audioPopup.visible
            }

            onWheel: {
                if (!defaultSink) return;

                if (wheel.angleDelta.y > 0)
                    defaultSink.volume += 0.05
                else
                    defaultSink.volume -= 0.05
            }
        }

        Text {
            anchors.centerIn: parent
            text: defaultSink && defaultSink.muted ? "󰝟" : "󰕾"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: "#f5c2e7"
        }
    }

    Popup {
        id: mixerPopup
        x: parent.x - 80
        y: parent.y + 40
        width: 260
        height: 160
        modal: false
        focus: true

        background: Rectangle {
            radius: 18
            color: "#181825"
            border.color: "#f38ba8"
            border.width: 2
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Audio Mixer"
                color: "#f5c2e7"
                font.pixelSize: 14
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

                background: Rectangle {
                    implicitHeight: 6
                    radius: 6
                    color: "#313244"
                }

                handle: Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: "#f5c2e7"
                }
            }

            Button {
                text: defaultSink.muted ? "Unmute" : "Mute"
                onClicked: defaultSink.muted = !defaultSink.muted

                background: Rectangle {
                    radius: 10
                    color: "#f38ba8"
                }
            }
        }
    }
}