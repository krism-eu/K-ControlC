import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 16

    Label { text: "Sistema"; font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label {
        Layout.fillWidth: true
        text: "Informazioni locali e accesso rapido agli strumenti di configurazione del desktop."
        color: "#94a3b8"; wrapMode: Text.Wrap
    }

    GridLayout {
        Layout.fillWidth: true
        columns: width > 760 ? 2 : 1
        columnSpacing: 12; rowSpacing: 12

        Repeater {
            model: [
                { title: "Sistema operativo", value: SystemBackend.osName, glyph: "◈" },
                { title: "Kernel", value: SystemBackend.kernelVersion, glyph: "K" },
                { title: "Architettura", value: SystemBackend.architecture, glyph: "CPU" },
                { title: "Nome host", value: SystemBackend.hostName, glyph: "⌂" },
                { title: "Memoria", value: SystemBackend.memorySummary, glyph: "RAM" },
                { title: "Storage root", value: SystemBackend.storageSummary, glyph: "▤" }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                radius: 12; color: "#131c38"; border.color: "#293761"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Rectangle {
                        width: 48; height: 48; radius: 10; color: "#202b57"
                        Label { anchors.centerIn: parent; text: modelData.glyph; color: "#a5b4fc"; font.bold: true }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label { text: modelData.title; color: "#64748b"; font.pixelSize: 10 }
                        Label { Layout.fillWidth: true; text: modelData.value; color: "#f8fafc"; font.pixelSize: 13; wrapMode: Text.Wrap }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: actions.implicitHeight + 30
        ColumnLayout {
            id: actions
            anchors.fill: parent; anchors.margins: 15; spacing: 10
            Label { text: "Configurazione desktop"; font.bold: true; color: "#e0e7ff"; font.pixelSize: 15 }
            RowLayout {
                Button {
                    text: "Impostazioni di sistema"
                    enabled: SystemBackend.toolAvailable("systemsettings")
                    onClicked: SystemBackend.launchTool("systemsettings")
                }
                Button {
                    text: "Centro informazioni"
                    enabled: SystemBackend.toolAvailable("kinfocenter")
                    onClicked: SystemBackend.launchTool("kinfocenter")
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Copia Quick Info"
                    onClicked: SystemBackend.copyToClipboard(SystemBackend.quickSystemInfo())
                }
            }
        }
    }
}
