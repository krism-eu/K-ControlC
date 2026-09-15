import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    Label { text: qsTr("Recovery"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: qsTr("Rollback BootC, risincronizzazione del layer persistente e accesso agli strumenti di recupero."); color: "#94a3b8"; wrapMode: Text.Wrap }
    Repeater {
        model: BootcBackend.deployments
        delegate: Label { required property var modelData; Layout.fillWidth: true; text: modelData.role + " · " + (modelData.version || modelData.image || qsTr("deployment")); color: modelData.role === "Booted" ? "#34d399" : "#cbd5e1"; wrapMode: Text.Wrap }
    }
    Flow { Layout.fillWidth: true; spacing: 8
        Button { text: qsTr("Rollback + apply"); enabled: BootcBackend.bootcAvailable && !PolkitHelper.running; onClicked: rollbackDialog.open() }
        Button { text: qsTr("Risincronizza rk"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/rk", ["sync"]) }
        Button { text: qsTr("Partition Manager"); enabled: SystemBackend.toolAvailable("partitionmanager"); onClicked: SystemBackend.launchTool("partitionmanager") }
        Button { text: qsTr("Log di boot"); onClicked: SystemBackend.launchQuickAction("journal") }
        Button { text: qsTr("Rimuovi Flatpak inutilizzati"); onClicked: SystemBackend.launchQuickAction("flatpak-unused") }
    }
    Label { Layout.fillWidth: true; text: qsTr("Non viene eseguito dnf distro-sync sul sistema base: su bootc la riparazione/aggiornamento della base passa dall'immagine e da bootc upgrade."); color: "#64748b"; font.pixelSize: 10; wrapMode: Text.Wrap }
    Dialog { id: rollbackDialog; modal: true; title: qsTr("Applicare il rollback?"); standardButtons: Dialog.Yes | Dialog.No; onAccepted: PolkitHelper.execute("/usr/bin/bootc", ["rollback", "--apply"]) }
}
