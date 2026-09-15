import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root; spacing: 16; property int refreshToken: 0
    property var services: [
        { id: "NetworkManager.service", title: qsTr("NetworkManager") },
        { id: "cups.service", title: qsTr("Stampa (CUPS)") },
        { id: "bluetooth.service", title: qsTr("Bluetooth") }
    ]
    Label { text: qsTr("Servizi"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { text: qsTr("Stato e riavvio controllato dei servizi desktop più comuni tramite systemd D-Bus."); color: "#94a3b8"; wrapMode: Text.Wrap; Layout.fillWidth: true }
    Repeater {
        model: root.services
        delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true; height: 82; radius: 10; color: "#131c38"; border.color: "#293761"
            RowLayout { anchors.fill: parent; anchors.margins: 12
                ColumnLayout { Layout.fillWidth: true; Label { text: modelData.title; color: "#eef2ff"; font.bold: true } Label { text: { root.refreshToken; return SystemBackend.serviceState(modelData.id) } color: "#94a3b8" } }
                Button { text: qsTr("Riavvia"); onClicked: SystemBackend.restartService(modelData.id) }
            }
        }
    }
    Button { text: qsTr("Aggiorna stati"); onClicked: root.refreshToken++ }
}
