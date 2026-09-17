import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Backup e recovery")

    property int backupProfileIndex: 0
    property var backupFiles: []
    property string restorePath: ""
    property string restoreName: ""

    function humanSize(bytes) {
        if (!bytes || bytes <= 0) return "0 B"
        if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GiB"
        if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MiB"
        if (bytes >= 1024) return (bytes / 1024).toFixed(1) + " KiB"
        return bytes + " B"
    }

    function refreshBackups() {
        root.backupFiles = SystemBackend.backups()
    }

    Component.onCompleted: refreshBackups()

    Connections {
        target: SystemBackend
        function onBackupStatusChanged() {
            if (!SystemBackend.backupBusy)
                root.refreshBackups()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { level: 2; text: qsTr("Crea backup") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                    text: qsTr("Archivi locali tar.gz in ~/krisCC Backups. Configurazione e home restano dati utente e non modificano il deployment BootC.")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Label { text: qsTr("Profilo:"); font.bold: true }
                    Controls.ComboBox {
                        id: backupProfile
                        Layout.preferredWidth: 260
                        model: [qsTr("Configurazione utente"), qsTr("Home personale")]
                        onCurrentIndexChanged: root.backupProfileIndex = currentIndex
                    }
                    Item { Layout.fillWidth: true }
                    Controls.Button {
                        text: qsTr("Apri cartella")
                        icon.name: "folder-open"
                        onClicked: SystemBackend.openBackupFolder()
                    }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.68
                    text: backupProfile.currentIndex === 0
                          ? qsTr("Include configurazioni Plasma/Konsole e file utente supportati. Minimo 1 GiB libero.")
                          : qsTr("Include la home, escludendo cache, cestino e backup precedenti. Minimo 5 GiB liberi.")
                }

                RowLayout {
                    Layout.fillWidth: true
                    Controls.Button {
                        text: qsTr("Crea backup")
                        icon.name: "document-save-all"
                        enabled: !SystemBackend.backupBusy
                        onClicked: backupProfile.currentIndex === 0
                                   ? SystemBackend.createSnapshot("config")
                                   : homeDialog.open()
                    }
                    Controls.Button {
                        visible: SystemBackend.backupBusy
                        text: qsTr("Annulla")
                        icon.name: "process-stop"
                        onClicked: SystemBackend.cancelSnapshot()
                    }
                    Controls.BusyIndicator { visible: SystemBackend.backupBusy; running: visible }
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
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading { Layout.fillWidth: true; level: 2; text: qsTr("Backup disponibili") }
                    Controls.Button {
                        text: qsTr("Aggiorna")
                        icon.name: "view-refresh"
                        onClicked: root.refreshBackups()
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.backupFiles.length === 0
                    type: Kirigami.MessageType.Information
                    text: qsTr("Nessun backup creato da krisCC.")
                }

                Repeater {
                    model: root.backupFiles
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { Layout.fillWidth: true; font.bold: true; text: modelData.name }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    opacity: 0.62
                                    text: (modelData.kind === "home" ? qsTr("Home") : qsTr("Configurazione"))
                                          + " · " + root.humanSize(modelData.size)
                                          + " · " + modelData.modified
                                }
                            }
                            Controls.Button {
                                text: qsTr("Verifica")
                                icon.name: "dialog-ok"
                                enabled: !SystemBackend.backupBusy
                                onClicked: SystemBackend.verifySnapshot(modelData.path)
                            }
                            Controls.Button {
                                text: qsTr("Ripristina")
                                icon.name: "edit-undo"
                                enabled: !SystemBackend.backupBusy
                                onClicked: {
                                    root.restorePath = modelData.path
                                    root.restoreName = modelData.name
                                    restoreDialog.open()
                                }
                            }
                        }
                    }
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
                    text: qsTr("KrisOS mantiene un solo deployment supportato. Il recovery del layer RPM usa il contratto rk: stato e risincronizzazione delle richieste persistenti, senza reset distruttivi automatici.")
                }
                RowLayout {
                    Controls.Button {
                        text: qsTr("Mostra stato rk")
                        icon.name: "documentinfo"
                        enabled: !UtilityBackend.busy
                        onClicked: UtilityBackend.runBookmark("rk-status")
                    }
                    Controls.Button {
                        text: qsTr("Risincronizza pacchetti")
                        icon.name: "view-refresh"
                        enabled: !PolkitHelper.running
                        onClicked: syncDialog.open()
                    }
                }
                Controls.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    visible: UtilityBackend.operationId === "bookmark.rk-status"
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: UtilityBackend.output
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
    }

    Controls.Dialog {
        id: homeDialog
        modal: true
        title: qsTr("Creare il backup della home?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("La home può essere grande e contenere dati sensibili. Cache, cestino e backup precedenti vengono esclusi.")
        }
        onAccepted: SystemBackend.createSnapshot("home")
    }

    Controls.Dialog {
        id: restoreDialog
        modal: true
        title: qsTr("Ripristinare %1?").arg(root.restoreName)
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("I file presenti nella home con lo stesso percorso possono essere sovrascritti. Il ripristino avviene come utente, senza modificare il deployment KrisOS.")
        }
        onAccepted: SystemBackend.restoreSnapshot(root.restorePath)
    }

    Controls.Dialog {
        id: syncDialog
        modal: true
        title: qsTr("Risincronizzare il layer RPM?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Esegue sudo rk sync sulle richieste persistenti già salvate.")
        }
        onAccepted: PolkitHelper.execute("/usr/bin/rk", ["sync"])
    }

    Controls.Dialog { id: rebootDialog; modal: true; title: qsTr("Riavviare il sistema?"); standardButtons: Controls.Dialog.Yes | Controls.Dialog.No; onAccepted: SystemBackend.sessionAction("reboot") }
    Controls.Dialog { id: powerDialog; modal: true; title: qsTr("Spegnere il sistema?"); standardButtons: Controls.Dialog.Yes | Controls.Dialog.No; onAccepted: SystemBackend.sessionAction("poweroff") }
}
