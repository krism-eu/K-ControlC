import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 16
    property var progressLines: []

    Connections {
        target: PolkitHelper
        function onLine(text) { root.progressLines = root.progressLines.concat([text]).slice(-14) }
        function onFinished(ok, output) { root.progressLines = root.progressLines.concat([ok ? qsTr("--- completato ---") : qsTr("--- fallito ---")]).slice(-14); BootcBackend.refreshStatus() }
    }

    Label { text: qsTr("Deployment e aggiornamenti BootC"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: qsTr("Stato strutturato dei deployment, aggiornamenti atomici e rollback. Le azioni mutanti passano da Polkit."); color: "#94a3b8"; wrapMode: Text.Wrap }

    RowLayout { Layout.fillWidth: true; BusyIndicator { visible: BootcBackend.busy; running: visible } Button { text: qsTr("Aggiorna stato"); enabled: !BootcBackend.busy; onClicked: BootcBackend.refreshStatus() } }
    Label { visible: BootcBackend.errorText.length > 0; Layout.fillWidth: true; text: BootcBackend.errorText; color: "#f59e0b"; wrapMode: Text.Wrap }

    Flow {
        Layout.fillWidth: true; spacing: 10
        Repeater {
            model: BootcBackend.deployments
            delegate: Rectangle {
                required property var modelData
                width: 280; height: 150; radius: 12; color: "#131c38"; border.color: modelData.role === "Booted" ? "#34d399" : "#293761"
                ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 4
                    Label { text: modelData.role + (modelData.pinned ? qsTr(" · pinned") : ""); color: "#a5b4fc"; font.bold: true }
                    Label { Layout.fillWidth: true; text: modelData.image || qsTr("immagine non indicata"); color: "#f8fafc"; wrapMode: Text.Wrap; maximumLineCount: 2 }
                    Label { text: modelData.version || ""; color: "#94a3b8" }
                    Label { Layout.fillWidth: true; text: modelData.digest || modelData.checksum || ""; color: "#64748b"; elide: Text.ElideMiddle; font.pixelSize: 9 }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; radius: 12; color: "#111831"; border.color: "#253158"; implicitHeight: actionCol.implicitHeight + 28
        ColumnLayout { id: actionCol; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Azioni"); font.bold: true; color: "#e0e7ff" }
            Flow { Layout.fillWidth: true; spacing: 8
                Button { text: qsTr("Controlla aggiornamenti"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/bootc", ["upgrade", "--check"]) }
                Button { text: qsTr("Scarica e prepara"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/bootc", ["upgrade"]) }
                Button { text: qsTr("Solo download"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/bootc", ["upgrade", "--download-only"]) }
                Button { text: qsTr("Applica"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: applyDialog.open() }
                Button { text: qsTr("Rollback"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: rollbackDialog.open() }
                Button { text: qsTr("Rollback + apply"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: rollbackApplyDialog.open() }
            }
            Label { text: qsTr("Il pin/rollback verso commit arbitrari non viene esposto finché la CLI bootc dell'immagine raku non è validata E2E."); color: "#64748b"; font.pixelSize: 10; wrapMode: Text.Wrap; Layout.fillWidth: true }
        }
    }

    TextArea { Layout.fillWidth: true; Layout.preferredHeight: 180; readOnly: true; text: BootcBackend.statusText; font.family: "monospace"; font.pixelSize: 10; color: "#cbd5e1"; wrapMode: Text.WrapAnywhere; background: Rectangle { color: "#0a1022"; radius: 8 } }

    Dialog { id: applyDialog; modal: true; title: qsTr("Applicare l'aggiornamento?"); standardButtons: Dialog.Yes | Dialog.No; onAccepted: PolkitHelper.execute("/usr/bin/bootc", ["upgrade", "--apply"]) }
    Dialog { id: rollbackDialog; modal: true; title: qsTr("Preparare il rollback?"); standardButtons: Dialog.Yes | Dialog.No; onAccepted: PolkitHelper.execute("/usr/bin/bootc", ["rollback"]) }
    Dialog { id: rollbackApplyDialog; modal: true; title: qsTr("Rollback e applicazione immediata?"); standardButtons: Dialog.Yes | Dialog.No; onAccepted: PolkitHelper.execute("/usr/bin/bootc", ["rollback", "--apply"]) }
}
