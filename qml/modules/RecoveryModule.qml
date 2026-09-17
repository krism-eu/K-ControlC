import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Backup e recovery")
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
            if (root.ownOperation) root.progressLines = root.progressLines.concat([text]).slice(-12)
        }
        function onFinished(ok, output) {
            if (!root.ownOperation) return
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
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { level: 2; text: qsTr("Backup locale") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Un solo flusso per configurazioni o cartelle personali. I backup sono normali archivi tar.gz in ~/krisCC Backups, non richiedono root e non toccano il deployment BootC.")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Profilo:"); font.bold: true }
                    Controls.ComboBox {
                        id: backupProfile
                        Layout.preferredWidth: 250
                        model: [qsTr("Configurazione utente"), qsTr("Home personale")]
                    }
                    Item { Layout.fillWidth: true }
                    Controls.Button {
                        text: qsTr("Apri cartella backup")
                        icon.name: "folder-open"
                        onClicked: SystemBackend.openBackupFolder()
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Controls.Label {
                            Layout.fillWidth: true
                            font.bold: true
                            text: backupProfile.currentIndex === 0 ? qsTr("Configurazione utente") : qsTr("Home personale")
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.75
                            text: backupProfile.currentIndex === 0
                                  ? qsTr("Include ~/.config e le cartelle Plasma/Konsole supportate quando presenti. È pensato per salvare preferenze e configurazioni, non i documenti personali.")
                                  : qsTr("Include la home personale ed esclude cache, cestino e la cartella krisCC Backups. Può contenere documenti, chiavi, token e altri dati sensibili.")
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Label {
                                Layout.fillWidth: true
                                opacity: 0.68
                                text: backupProfile.currentIndex === 0
                                      ? qsTr("Spazio minimo richiesto: 1 GiB libero")
                                      : qsTr("Spazio minimo richiesto: 5 GiB liberi")
                            }
                            Controls.Button {
                                text: qsTr("Crea backup")
                                icon.name: "document-save-all"
                                enabled: !SystemBackend.backupBusy
                                onClicked: backupProfile.currentIndex === 0 ? SystemBackend.createSnapshot("config") : homeDialog.open()
                            }
                            Controls.Button {
                                visible: SystemBackend.backupBusy
                                text: qsTr("Annulla")
                                icon.name: "process-stop"
                                onClicked: SystemBackend.cancelSnapshot()
                            }
                            Controls.BusyIndicator { visible: SystemBackend.backupBusy; running: visible }
                        }
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: SystemBackend.backupStatus.length > 0
                    type: SystemBackend.backupState === "success" ? Kirigami.MessageType.Positive
                          : SystemBackend.backupState === "warning" ? Kirigami.MessageType.Warning
                          : SystemBackend.backupState === "error" ? Kirigami.MessageType.Error
                          : Kirigami.MessageType.Information
                    text: SystemBackend.backupStatus + (SystemBackend.backupPath.length > 0 ? "\n" + SystemBackend.backupPath : "")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label { Layout.fillWidth: true; opacity: 0.65; text: qsTr("Destinazione: ~/krisCC Backups") }
                    Controls.Label { opacity: 0.65; text: qsTr("Formato: tar.gz") }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Recovery KrisOS") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                    text: qsTr("KrisOS supporta un solo deployment. Se il layer RPM persistente deve essere ricostruito, rk può risincronizzare le richieste salvate sull'overlay attivo.")
                }
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
                        text: qsTr("Risincronizza pacchetti persistenti")
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
                Kirigami.Heading { level: 3; text: qsTr("Operazione") }
                Repeater {
                    model: root.progressLines
                    delegate: Controls.Label { required property string modelData; Layout.fillWidth: true; wrapMode: Text.WrapAnywhere; font.family: "monospace"; text: modelData }
                }
            }
        }
    }

    Controls.Dialog {
        id: homeDialog
        modal: true
        title: qsTr("Creare il backup della home?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("La home può essere molto grande e può contenere dati sensibili. Cache, cestino e backup precedenti vengono esclusi. L'operazione non parte con meno di 5 GiB liberi.")
        }
        onAccepted: SystemBackend.createSnapshot("home")
    }
    Controls.Dialog { id: rebootDialog; modal: true; title: qsTr("Riavviare il sistema?"); standardButtons: Controls.Dialog.Yes | Controls.Dialog.No; onAccepted: SystemBackend.sessionAction("reboot") }
    Controls.Dialog { id: powerDialog; modal: true; title: qsTr("Spegnere il sistema?"); standardButtons: Controls.Dialog.Yes | Controls.Dialog.No; onAccepted: SystemBackend.sessionAction("poweroff") }
}
