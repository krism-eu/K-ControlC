import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    Label { text: qsTr("Diagnostica e log"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    TextArea { id: info; Layout.fillWidth: true; Layout.preferredHeight: 260; readOnly: true; text: SystemBackend.quickSystemInfo(); font.family: "monospace"; color: "#cbd5e1"; background: Rectangle { color: "#0a1022"; radius: 8 } }
    Flow { Layout.fillWidth: true; spacing: 8
        Button { text: qsTr("Copia Quick Info"); onClicked: SystemBackend.copyToClipboard(info.text) }
        Button { text: qsTr("Warning del boot"); onClicked: SystemBackend.launchQuickAction("journal") }
        Button { text: qsTr("KSystemLog"); enabled: SystemBackend.toolAvailable("ksystemlog"); onClicked: SystemBackend.launchTool("ksystemlog") }
        Button { text: qsTr("Terminale"); enabled: SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchTool("konsole") }
    }
}
