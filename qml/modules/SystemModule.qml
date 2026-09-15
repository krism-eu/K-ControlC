import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 16

    Label { text: qsTr("Sistema"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: qsTr("Identità del sistema, data/ora, NTP e azioni di sessione tramite systemd-logind."); color: "#94a3b8"; wrapMode: Text.Wrap }

    GridLayout {
        Layout.fillWidth: true
        columns: width > 760 ? 2 : 1
        columnSpacing: 12; rowSpacing: 12
        Repeater {
            model: [
                { title: qsTr("Sistema operativo"), value: SystemBackend.osName },
                { title: qsTr("Kernel"), value: SystemBackend.kernelVersion },
                { title: qsTr("Architettura"), value: SystemBackend.architecture },
                { title: qsTr("Nome host"), value: SystemBackend.hostName },
                { title: qsTr("Memoria"), value: SystemBackend.memorySummary },
                { title: qsTr("Storage root"), value: SystemBackend.storageSummary }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredHeight: 82
                radius: 10; color: "#131c38"; border.color: "#293761"
                ColumnLayout { anchors.fill: parent; anchors.margins: 12
                    Label { text: modelData.title; color: "#64748b"; font.pixelSize: 10 }
                    Label { Layout.fillWidth: true; text: modelData.value; color: "#f8fafc"; font.pixelSize: 13; wrapMode: Text.Wrap }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: timeCol.implicitHeight + 28
        ColumnLayout {
            id: timeCol; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Data, ora e sincronizzazione"); font.bold: true; color: "#e0e7ff"; font.pixelSize: 15 }
            Label { text: qsTr("Fuso orario: %1 · NTP: %2").arg(SystemBackend.timeZone).arg(SystemBackend.ntpEnabled() ? qsTr("attivo") : qsTr("disattivo")); color: "#cbd5e1" }
            RowLayout {
                Button { text: qsTr("Attiva NTP"); onClicked: SystemBackend.setNtpEnabled(true) }
                Button { text: qsTr("Disattiva NTP"); onClicked: SystemBackend.setNtpEnabled(false) }
                Button { text: qsTr("Impostazioni data/ora"); onClicked: if (!SystemBackend.launchKcm("kcm_clock")) SystemBackend.launchTool("systemsettings") }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: sessionCol.implicitHeight + 28
        ColumnLayout {
            id: sessionCol; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Sessione"); font.bold: true; color: "#e0e7ff"; font.pixelSize: 15 }
            Label { text: SystemBackend.desktopSession; color: "#94a3b8" }
            RowLayout {
                Button { text: qsTr("Sospendi"); onClicked: SystemBackend.sessionAction("suspend") }
                Button { text: qsTr("Riavvia"); onClicked: rebootDialog.open() }
                Button { text: qsTr("Spegni"); onClicked: powerDialog.open() }
                Item { Layout.fillWidth: true }
                Button { text: qsTr("Impostazioni di sistema"); onClicked: SystemBackend.launchTool("systemsettings") }
            }
        }
    }

    Dialog { id: rebootDialog; modal: true; title: qsTr("Riavviare il sistema?"); standardButtons: Dialog.Yes | Dialog.No; onAccepted: SystemBackend.sessionAction("reboot") }
    Dialog { id: powerDialog; modal: true; title: qsTr("Spegnere il sistema?"); standardButtons: Dialog.Yes | Dialog.No; onAccepted: SystemBackend.sessionAction("poweroff") }
}
