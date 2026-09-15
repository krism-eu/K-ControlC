import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    Label { text: qsTr("Storage"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { text: qsTr("Spazio del filesystem root, partizioni e layer persistente raku."); color: "#94a3b8"; Layout.fillWidth: true; wrapMode: Text.Wrap }
    Rectangle { Layout.fillWidth: true; radius: 12; color: "#131c38"; border.color: "#293761"; implicitHeight: col.implicitHeight + 30
        ColumnLayout { id: col; anchors.fill: parent; anchors.margins: 15; spacing: 10
            Label { text: qsTr("Root: %1").arg(SystemBackend.storageSummary); color: "#e0e7ff"; font.bold: true }
            Label { text: qsTr("Pacchetti persistenti: %1").arg(BootcBackend.persistentPackageCount); color: "#cbd5e1" }
            Label { text: BootcBackend.persistentPackages; color: "#94a3b8"; wrapMode: Text.Wrap; Layout.fillWidth: true }
            Button { text: qsTr("Apri Partition Manager"); enabled: SystemBackend.toolAvailable("partitionmanager"); onClicked: SystemBackend.launchTool("partitionmanager") }
        }
    }
}
