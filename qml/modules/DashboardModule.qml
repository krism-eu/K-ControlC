import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 18
    signal openPage(int index)

    Label {
        text: "Panoramica"
        font.pixelSize: 26
        font.bold: true
        color: "#f8fafc"
    }
    Label {
        text: "Controllo rapido del sistema, ispirato alla praticità di MX Tools con organizzazione da control center."
        color: "#94a3b8"
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    GridLayout {
        Layout.fillWidth: true
        columns: width > 780 ? 3 : 1
        columnSpacing: 12
        rowSpacing: 12

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 128
            radius: 12; color: "#131c38"; border.color: "#293761"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16
                Label { text: "Sistema"; color: "#818cf8"; font.bold: true }
                Label { text: SystemBackend.osName; color: "#f8fafc"; font.pixelSize: 15; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                Label { text: SystemBackend.kernelVersion; color: "#94a3b8"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 128
            radius: 12; color: "#131c38"; border.color: BootcBackend.bootcAvailable ? "#315b58" : "#293761"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16
                Label { text: "BootC"; color: "#34d399"; font.bold: true }
                Label { text: BootcBackend.bootcAvailable ? "Sistema image-based rilevato" : "bootc non disponibile"; color: "#f8fafc"; font.pixelSize: 14 }
                Item { Layout.fillHeight: true }
                Button { text: "Gestisci aggiornamenti"; enabled: BootcBackend.bootcAvailable; onClicked: root.openPage(2) }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 128
            radius: 12; color: "#131c38"; border.color: "#293761"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16
                Label { text: "Pacchetti persistenti"; color: "#c4b5fd"; font.bold: true }
                Label { text: BootcBackend.persistentPackageCount.toString(); color: "#f8fafc"; font.pixelSize: 28; font.bold: true }
                Item { Layout.fillHeight: true }
                Button { text: "Apri Software"; onClicked: root.openPage(1) }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 205
            radius: 12
            color: "#111831"
            border.color: "#253158"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 8
                Label { text: "Quick System Info"; font.bold: true; font.pixelSize: 15; color: "#e0e7ff" }
                TextArea {
                    id: quickInfo
                    Layout.fillWidth: true; Layout.fillHeight: true
                    readOnly: true
                    text: SystemBackend.quickSystemInfo()
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: "#cbd5e1"
                    background: Rectangle { color: "#0b1124"; radius: 8 }
                }
                Button { text: "Copia negli appunti"; onClicked: SystemBackend.copyToClipboard(quickInfo.text) }
            }
        }

        Rectangle {
            Layout.preferredWidth: 300
            Layout.preferredHeight: 205
            radius: 12
            color: "#111831"
            border.color: "#253158"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 8
                Label { text: "Risorse"; font.bold: true; font.pixelSize: 15; color: "#e0e7ff" }
                Label { text: "RAM"; color: "#64748b"; font.pixelSize: 10 }
                Label { text: SystemBackend.memorySummary; color: "#f8fafc" }
                Label { text: "Disco /"; color: "#64748b"; font.pixelSize: 10 }
                Label { text: SystemBackend.storageSummary; color: "#f8fafc"; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Label { text: "Sessione"; color: "#64748b"; font.pixelSize: 10 }
                Label { text: SystemBackend.desktopSession; color: "#f8fafc"; wrapMode: Text.Wrap; Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                Button { text: "Strumenti di sistema"; onClicked: root.openPage(4) }
            }
        }
    }
}
