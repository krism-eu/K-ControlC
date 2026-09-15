import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Recovery e backup")
    property bool ownOperation: false
    property var progressLines: []

    function runPrivileged(program, args) {
        root.ownOperation = true
        root.progressLines = []
        PolkitHelper.execute(program, args)
    }

    Connections {
        target: PolkitHelper
        function onLine(text) {
            if (root.ownOperation)
                root.progressLines = root.progressLines.concat([text]).slice(-12)
        }
        function onFinished(ok, output) {
            if (!root.ownOperation)
                return
            root.ownOperation = false
            root.progressLines = root.progressLines.concat([ok ? qsTr("--- completato ---") : qsTr("--- fallito ---")]).slice(-12)
            BootcBackend.refreshStatus()
            BootcBackend.refreshPackages()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Snapshot dei tuoi dati") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Gli snapshot sono normali archivi tar.gz nella cartella ~/K-ControlC Backups. Non richiedono root e sono indipendenti dai deployment BootC.")
                }
                RowLayout {
                    Controls.Button {
                        text: qsTr("Snapshot configurazione")
                        icon.name: "document-save-all"
                        enabled: !SystemBackend.backupBusy
                        onClicked: SystemBackend.createSnapshot("config")
                    }
                    Controls.Button {
                        text: qsTr("Snapshot home")
                        icon.name: "user-home"
                        enabled: !SystemBackend.backupBusy
                        onClicked: homeDialog.open()
                    }
                    Controls.Button {
                        text: qsTr("Apri cartella backup")
                        icon.name: "folder-open"
                        onClicked: SystemBackend.openBackupFolder()
                    }
                    Controls.BusyIndicator {
                        visible: SystemBackend.backupBusy
                        running: visible
                    }
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: SystemBackend.backupStatus.length > 0
                    type: SystemBackend.backupStatus.indexOf(qsTr("correttamente")) >= 0
                          ? Kirigami.MessageType.Positive : Kirigami.MessageType.Information
                    text: SystemBackend.backupStatus + (SystemBackend.backupPath.length > 0 ? "\n" + SystemBackend.backupPath : "")
                }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.7
                    text: qsTr("Lo snapshot configurazione include ~/.config e alcune cartelle Plasma/Konsole presenti. Lo snapshot home esclude cache, cestino e la cartella dei backup per evitare ricorsioni.")
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Recovery BootC") }
                Repeater {
                    model: BootcBackend.deployments
                    delegate: Controls.Label {
                        required property var modelData
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: modelData.role + " · " + (modelData.version || modelData.image || qsTr("deployment"))
                    }
                }
                RowLayout {
                    Controls.Button {
                        text: qsTr("Prepara rollback")
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: rollbackDialog.open()
                    }
                    Controls.Button {
                        text: qsTr("Rollback + apply")
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: rollbackApplyDialog.open()
                    }
                    Controls.Button {
                        text: qsTr("Risincronizza rk")
                        enabled: !PolkitHelper.running
                        onClicked: root.runPrivileged("/usr/bin/rk", ["sync"])
                    }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Sessione") }
                RowLayout {
                    Controls.Button { text: qsTr("Sospendi"); icon.name: "system-suspend"; onClicked: SystemBackend.sessionAction("suspend") }
                    Controls.Button { text: qsTr("Riavvia"); icon.name: "system-reboot"; onClicked: rebootDialog.open() }
                    Controls.Button { text: qsTr("Spegni"); icon.name: "system-shutdown"; onClicked: powerDialog.open() }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: root.progressLines.length > 0
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Operazione") }
                Repeater {
                    model: root.progressLines
                    delegate: Controls.Label {
                        required property string modelData
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAnywhere
                        font.family: "monospace"
                        text: modelData
                    }
                }
            }
        }
    }

    Controls.Dialog {
        id: homeDialog
        modal: true
        title: qsTr("Creare uno snapshot della home?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Può essere molto grande e può contenere documenti, chiavi, token e altri dati personali. Cache, cestino e backup precedenti vengono esclusi.")
        }
        onAccepted: SystemBackend.createSnapshot("home")
    }
    Controls.Dialog {
        id: rollbackDialog
        modal: true
        title: qsTr("Preparare il rollback BootC?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: root.runPrivileged("/usr/bin/bootc", ["rollback"])
    }
    Controls.Dialog {
        id: rollbackApplyDialog
        modal: true
        title: qsTr("Rollback e applicazione immediata?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: root.runPrivileged("/usr/bin/bootc", ["rollback", "--apply"])
    }
    Controls.Dialog {
        id: rebootDialog
        modal: true
        title: qsTr("Riavviare il sistema?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: SystemBackend.sessionAction("reboot")
    }
    Controls.Dialog {
        id: powerDialog
        modal: true
        title: qsTr("Spegnere il sistema?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: SystemBackend.sessionAction("poweroff")
    }
}
