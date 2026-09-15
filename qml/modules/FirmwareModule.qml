import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    Label { text: qsTr("Firmware"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: SystemBackend.programAvailable("fwupdmgr") ? qsTr("fwupd rilevato: puoi controllare gli aggiornamenti firmware disponibili.") : qsTr("fwupd non è installato nell'immagine corrente."); color: "#94a3b8"; wrapMode: Text.Wrap }
    Flow { Layout.fillWidth: true; spacing: 8
        Button { text: qsTr("Controlla con fwupdmgr"); enabled: SystemBackend.programAvailable("fwupdmgr"); onClicked: SystemBackend.launchQuickAction("firmware") }
        Button { text: qsTr("Apri Discover"); enabled: SystemBackend.toolAvailable("discover"); onClicked: SystemBackend.launchTool("discover") }
    }
}
