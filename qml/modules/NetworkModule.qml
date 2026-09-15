import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root; spacing: 16; property int refreshToken: 0
    Label { text: qsTr("Rete"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: qsTr("Connettività NetworkManager e accesso rapido alla configurazione Plasma."); color: "#94a3b8"; wrapMode: Text.Wrap }
    Rectangle { Layout.fillWidth: true; radius: 12; color: "#131c38"; border.color: "#293761"; implicitHeight: col.implicitHeight + 28
        ColumnLayout { id: col; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Connettività: %1").arg(SystemBackend.networkState()); color: "#e0e7ff"; font.bold: true }
            Label { text: { root.refreshToken; return qsTr("NetworkManager: %1").arg(SystemBackend.serviceState("NetworkManager.service")) } color: "#cbd5e1" }
            RowLayout { Button { text: qsTr("Configura rete"); onClicked: if (!SystemBackend.launchKcm("kcm_networkmanagement")) SystemBackend.launchTool("systemsettings") } Button { text: qsTr("Riavvia NetworkManager"); onClicked: SystemBackend.restartService("NetworkManager.service") } Button { text: qsTr("Aggiorna"); onClicked: root.refreshToken++ } }
        }
    }
}
