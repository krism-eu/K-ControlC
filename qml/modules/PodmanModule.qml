import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Container")

    property var containers: []
    property string parseError: ""
    property string selectedName: ""
    property bool refreshAfterAction: false

    function refresh() {
        root.parseError = ""
        UtilityBackend.runPodman("list")
    }

    function parseList() {
        if (UtilityBackend.busy || UtilityBackend.operationId !== "podman.list")
            return
        if (UtilityBackend.resultState !== "success") {
            root.containers = []
            root.parseError = UtilityBackend.output.length > 0 ? UtilityBackend.output : qsTr("Impossibile leggere l'elenco Podman.")
            return
        }
        try {
            var data = JSON.parse(UtilityBackend.output || "[]")
            root.containers = Array.isArray(data) ? data : []
            root.parseError = ""
        } catch (e) {
            root.containers = []
            root.parseError = UtilityBackend.output.length > 0 ? UtilityBackend.output : qsTr("Output Podman non leggibile.")
        }
    }

    function containerName(item) {
        if (!item) return ""
        if (Array.isArray(item.Names)) return item.Names.length ? item.Names[0] : ""
        return item.Names || item.Name || ""
    }

    function containerImage(item) {
        return item ? (item.Image || item.ImageName || "") : ""
    }

    function containerState(item) {
        return item ? (item.Status || item.State || "") : ""
    }

    function containerSize(item) {
        if (!item) return qsTr("n/d")
        if (item.Size) return item.Size
        if (item.SizeRw !== undefined || item.SizeRootFs !== undefined) {
            var rw = item.SizeRw !== undefined ? item.SizeRw : 0
            var rootfs = item.SizeRootFs !== undefined ? item.SizeRootFs : 0
            return qsTr("RW %1 · totale %2").arg(rw).arg(rootfs)
        }
        return qsTr("n/d")
    }

    function runAction(mode, name) {
        root.refreshAfterAction = true
        UtilityBackend.runPodman(mode, name)
    }

    Component.onCompleted: if (SystemBackend.programAvailable("podman")) root.refresh()

    Connections {
        target: UtilityBackend
        function onStateChanged() {
            if (UtilityBackend.busy)
                return
            if (root.refreshAfterAction) {
                root.refreshAfterAction = false
                refreshTimer.restart()
            } else {
                root.parseList()
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Kirigami.Heading { level: 2; text: qsTr("Podman") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.75
                text: qsTr("Container dell'utente corrente: stato, immagine e dimensione, con le azioni più comuni. Nessuna cancellazione automatica.")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Controls.Button {
                text: qsTr("Aggiorna")
                icon.name: "view-refresh"
                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("podman")
                onClicked: root.refresh()
            }
            Item { Layout.fillWidth: true }
            Controls.Label {
                opacity: 0.65
                text: qsTr("%1 container").arg(root.containers.length)
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !SystemBackend.programAvailable("podman")
            type: Kirigami.MessageType.Information
            text: qsTr("Podman non è installato nel sistema.")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: root.parseError.length > 0
            type: Kirigami.MessageType.Error
            text: root.parseError
        }

        Controls.BusyIndicator {
            visible: UtilityBackend.busy
            running: visible
            Layout.alignment: Qt.AlignHCenter
        }

        Repeater {
            model: root.containers
            delegate: Kirigami.AbstractCard {
                required property var modelData
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing
                    RowLayout {
                        Layout.fillWidth: true
                        Controls.Label {
                            Layout.fillWidth: true
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                            text: root.containerName(modelData)
                            elide: Text.ElideRight
                        }
                        Controls.Label {
                            font.bold: true
                            opacity: 0.72
                            text: root.containerState(modelData)
                        }
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        text: root.containerImage(modelData)
                        opacity: 0.72
                        elide: Text.ElideMiddle
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        text: qsTr("Dimensione: %1").arg(root.containerSize(modelData))
                        opacity: 0.72
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Controls.Button { text: qsTr("Info"); icon.name: "documentinfo"; onClicked: UtilityBackend.runPodman("info", root.containerName(modelData)) }
                        Controls.Button { text: qsTr("Log"); icon.name: "text-x-log"; onClicked: UtilityBackend.runPodman("logs", root.containerName(modelData)) }
                        Item { Layout.fillWidth: true }
                        Controls.Button { text: qsTr("Avvia"); enabled: !UtilityBackend.busy; onClicked: root.runAction("start", root.containerName(modelData)) }
                        Controls.Button { text: qsTr("Ferma"); enabled: !UtilityBackend.busy; onClicked: root.runAction("stop", root.containerName(modelData)) }
                        Controls.Button { text: qsTr("Riavvia"); enabled: !UtilityBackend.busy; onClicked: root.runAction("restart", root.containerName(modelData)) }
                        Controls.Button {
                            text: qsTr("Rinomina")
                            enabled: !UtilityBackend.busy
                            onClicked: {
                                root.selectedName = root.containerName(modelData)
                                renameField.text = root.selectedName
                                renameDialog.open()
                            }
                        }
                    }
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: SystemBackend.programAvailable("podman") && !UtilityBackend.busy && root.containers.length === 0 && root.parseError.length === 0
            type: Kirigami.MessageType.Information
            text: qsTr("Nessun container Podman presente per l'utente.")
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: UtilityBackend.operationId.indexOf("podman.") === 0
                  && UtilityBackend.operationId !== "podman.list" && UtilityBackend.output.length > 0
            contentItem: ColumnLayout {
                Controls.Label { font.bold: true; text: UtilityBackend.title }
                Controls.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: UtilityBackend.output
                }
            }
        }
    }

    Controls.Dialog {
        id: renameDialog
        modal: true
        title: qsTr("Rinomina container")
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        contentItem: ColumnLayout {
            Controls.Label { text: qsTr("Nuovo nome per %1").arg(root.selectedName) }
            Controls.TextField { id: renameField; Layout.fillWidth: true; selectByMouse: true }
        }
        onAccepted: {
            var next = renameField.text.trim()
            if (next.length > 0 && next !== root.selectedName) {
                root.refreshAfterAction = true
                UtilityBackend.runPodman("rename", root.selectedName, next)
            }
        }
    }
}
