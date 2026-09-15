import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 16
    property var progressLines: []
    property string lastResult: ""

    Connections {
        target: PolkitHelper
        function onLine(text) {
            root.progressLines = root.progressLines.concat([text]).slice(-14)
        }
        function onFinished(ok, output) {
            root.lastResult = output
            root.progressLines = root.progressLines.concat([
                ok ? "--- operazione completata ---" : "--- operazione fallita ---"
            ]).slice(-14)
            BootcBackend.refreshStatus()
        }
    }

    Label { text: "Aggiornamenti e rollback"; font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label {
        Layout.fillWidth: true
        text: "Gestione atomica dell'immagine di sistema tramite bootc. Gli aggiornamenti vengono preparati come deployment A/B e possono essere annullati con rollback."
        color: "#94a3b8"; wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: statusCol.implicitHeight + 30
        ColumnLayout {
            id: statusCol
            anchors.fill: parent; anchors.margins: 15; spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Label { text: "Stato BootC"; font.pixelSize: 15; font.bold: true; color: "#c7d2fe" }
                Item { Layout.fillWidth: true }
                BusyIndicator { visible: BootcBackend.busy; running: visible; Layout.preferredWidth: 24; Layout.preferredHeight: 24 }
                Button { text: "Aggiorna stato"; enabled: !BootcBackend.busy; onClicked: BootcBackend.refreshStatus() }
            }
            Label {
                visible: BootcBackend.errorText.length > 0
                text: BootcBackend.errorText
                color: "#f87171"; wrapMode: Text.Wrap; Layout.fillWidth: true
            }
            TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 210
                readOnly: true
                text: BootcBackend.statusText
                font.family: "monospace"
                font.pixelSize: 11
                color: "#cbd5e1"
                wrapMode: Text.WrapAnywhere
                background: Rectangle { color: "#0a1022"; radius: 8 }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: actionCol.implicitHeight + 30
        ColumnLayout {
            id: actionCol
            anchors.fill: parent; anchors.margins: 15; spacing: 10
            Label { text: "Azioni"; font.pixelSize: 15; font.bold: true; color: "#e0e7ff" }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Button {
                    text: "Controlla aggiornamenti"
                    enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                    onClicked: { root.progressLines = []; PolkitHelper.execute("/usr/bin/bootc", ["upgrade", "--check"]) }
                }
                Button {
                    text: "Scarica e prepara"
                    enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                    onClicked: { root.progressLines = []; PolkitHelper.execute("/usr/bin/bootc", ["upgrade"]) }
                }
                Button {
                    text: "Scarica soltanto"
                    enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                    onClicked: { root.progressLines = []; PolkitHelper.execute("/usr/bin/bootc", ["upgrade", "--download-only"]) }
                }
                Button {
                    text: "Applica e riavvia"
                    enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                    onClicked: applyDialog.open()
                }
                Button {
                    text: "Prepara rollback"
                    enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                    onClicked: rollbackDialog.open()
                }
            }
            Label {
                Layout.fillWidth: true
                text: "Le azioni che modificano il deployment richiedono autenticazione amministrativa tramite Polkit."
                color: "#64748b"; font.pixelSize: 10; wrapMode: Text.Wrap
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.progressLines.length > 0 || root.lastResult.length > 0
        radius: 12; color: "#0d152b"; border.color: "#253158"
        implicitHeight: progressCol.implicitHeight + 26
        ColumnLayout {
            id: progressCol
            anchors.fill: parent; anchors.margins: 13; spacing: 3
            Label { text: "Output operazione"; color: "#a5b4fc"; font.bold: true }
            Repeater {
                model: root.progressLines
                Label { required property string modelData; text: modelData; color: "#cbd5e1"; font.family: "monospace"; font.pixelSize: 10; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
            }
        }
    }

    Dialog {
        id: applyDialog
        title: "Applicare l'aggiornamento?"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            root.progressLines = []
            PolkitHelper.execute("/usr/bin/bootc", ["upgrade", "--apply"])
        }
        Label { text: "Il sistema può riavviarsi automaticamente per entrare nel nuovo deployment."; wrapMode: Text.Wrap; width: 420 }
    }

    Dialog {
        id: rollbackDialog
        title: "Preparare il rollback?"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            root.progressLines = []
            PolkitHelper.execute("/usr/bin/bootc", ["rollback"])
        }
        Label { text: "Il deployment precedente verrà impostato come prossimo avvio. Un eventuale aggiornamento staged verrà scartato."; wrapMode: Text.Wrap; width: 420 }
    }
}
