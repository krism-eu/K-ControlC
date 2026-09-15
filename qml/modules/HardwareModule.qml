import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    Label { text: qsTr("Hardware"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { text: qsTr("Informazioni hardware e scorciatoie agli strumenti specialistici installati."); color: "#94a3b8"; Layout.fillWidth: true; wrapMode: Text.Wrap }
    Rectangle { Layout.fillWidth: true; radius: 12; color: "#131c38"; border.color: "#293761"; implicitHeight: col.implicitHeight + 28
        ColumnLayout { id: col; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Architettura: %1").arg(SystemBackend.architecture); color: "#e0e7ff" }
            Label { text: qsTr("Memoria: %1").arg(SystemBackend.memorySummary); color: "#cbd5e1" }
            Flow { Layout.fillWidth: true; spacing: 8
                Button { text: qsTr("Centro informazioni"); enabled: SystemBackend.toolAvailable("kinfocenter"); onClicked: SystemBackend.launchTool("kinfocenter") }
                Button { text: qsTr("Bluetooth"); onClicked: if (!SystemBackend.launchKcm("kcm_bluetooth")) SystemBackend.launchTool("systemsettings") }
                Button { text: qsTr("Stampanti"); onClicked: if (!SystemBackend.launchKcm("kcm_printer_manager")) SystemBackend.launchTool("printer") }
                Button { text: qsTr("Virtualizzazione"); enabled: SystemBackend.toolAvailable("virtmanager"); onClicked: SystemBackend.launchTool("virtmanager") }
            }
        }
    }
}
