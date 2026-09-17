import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("BootC")
    property bool ownOperation: false
    property var progressLines: []

    function runBootc(args) {
        root.ownOperation = true
        root.progressLines = []
        PolkitHelper.execute("/usr/bin/bootc", args)
    }

    Connections {
        target: PolkitHelper
        function onLine(text) {
            if (root.ownOperation)
                root.progressLines = root.progressLines.concat([text]).slice(-14)
        }
        function onFinished(ok, output) {
            if (!root.ownOperation)
                return
            root.ownOperation = false
            root.progressLines = root.progressLines.concat([ok ? qsTr("--- completato ---") : qsTr("--- fallito ---")]).slice(-14)
            BootcBackend.refreshStatus()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("KrisOS usa un solo deployment supportato. Gli aggiornamenti del sistema sono image-based tramite BootC; i pacchetti persistenti restano gestiti separatamente da rk.")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: BootcBackend.errorText.length > 0
            type: Kirigami.MessageType.Warning
            text: BootcBackend.errorText
        }

        RowLayout {
            Controls.BusyIndicator { visible: BootcBackend.busy; running: visible }
            Controls.Button {
                text: qsTr("Aggiorna stato")
                icon.name: "view-refresh"
                enabled: !BootcBackend.busy
                onClicked: BootcBackend.refreshStatus()
            }
        }

        Repeater {
            model: BootcBackend.deployments
            delegate: Kirigami.AbstractCard {
                required property var modelData
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading {
                        level: 2
                        text: modelData.role + (modelData.pinned ? qsTr(" · pinned") : "")
                    }
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: modelData.image || qsTr("immagine non indicata") }
                    Controls.Label { Layout.fillWidth: true; text: modelData.version || "" }
                    Controls.Label { Layout.fillWidth: true; elide: Text.ElideMiddle; opacity: 0.7; text: modelData.digest || modelData.checksum || "" }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Aggiornamenti KrisOS") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                    text: qsTr("Il controllo interroga direttamente il registro configurato per l'immagine corrente. Con KrisOS pubblicato su GHCR, BootC scarica solo manifest e configurazione per verificare se il digest remoto è cambiato; non scarica i layer durante il controllo.")
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Controls.Button {
                        text: qsTr("Controlla GHCR")
                        icon.name: "view-refresh"
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: root.runBootc(["upgrade", "--check"])
                    }
                    Controls.Button {
                        text: qsTr("Scarica e prepara")
                        icon.name: "download"
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: root.runBootc(["upgrade"])
                    }
                    Controls.Button {
                        text: qsTr("Solo download")
                        icon.name: "download"
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: root.runBootc(["upgrade", "--download-only"])
                    }
                    Controls.Button {
                        text: qsTr("Applica")
                        icon.name: "system-reboot"
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: applyDialog.open()
                    }
                }
            }
        }

        Controls.TextArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            readOnly: true
            wrapMode: TextEdit.WrapAnywhere
            font.family: "monospace"
            text: BootcBackend.statusText
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: root.progressLines.length > 0
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Operazione BootC") }
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
        id: applyDialog
        modal: true
        title: qsTr("Applicare l'aggiornamento?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("BootC applicherà l'immagine preparata e riavvierà il sistema se necessario.")
        }
        onAccepted: root.runBootc(["upgrade", "--apply"])
    }
}
