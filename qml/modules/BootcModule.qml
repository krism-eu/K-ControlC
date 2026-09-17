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
                Kirigami.Heading { level: 2; text: qsTr("Aggiornamenti") }
                Flow {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Controls.Button {
                        text: qsTr("Controlla")
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: root.runBootc(["upgrade", "--check"])
                    }
                    Controls.Button {
                        text: qsTr("Scarica e prepara")
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: root.runBootc(["upgrade"])
                    }
                    Controls.Button {
                        text: qsTr("Solo download")
                        enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                        onClicked: root.runBootc(["upgrade", "--download-only"])
                    }
                    Controls.Button {
                        text: qsTr("Applica")
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
        id: applyDialog
        modal: true
        title: qsTr("Applicare l'aggiornamento?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: root.runBootc(["upgrade", "--apply"])
    }
}
