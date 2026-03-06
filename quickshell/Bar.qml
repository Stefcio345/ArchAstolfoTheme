import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import "components"

PanelWindow {
    id: bar

    property var popup

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 36


    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#1e1e2ecc"   // <-- add transparency here instead
        border.color: "#f38ba8"
        border.width: 2
    }

    RowLayout {

        anchors.fill: parent
        anchors.margins: 10
        spacing: 14

        Item { Layout.fillWidth: true }

        AudioWidget {
            popup: audioPopup
        }

        Item { Layout.fillWidth: true }
    }
}