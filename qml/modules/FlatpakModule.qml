import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Flatpak")
    property string mode: "search"
    property string lastQuery: ""

    function rows() {
        if (!UtilityBackend.output || UtilityBackend.output === qsTr("Nessun output."))
            return []
        var lines = UtilityBackend.output.split("\n")
        var result = []
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()
            if (!line)
                continue
            var fields = line.split("\t")
            if (fields.length < 2)
                continue
            result.push(fields)
        }
        return result
    }

    function run(newMode, query) {
        root.mode = newMode
        root.lastQuery = query || ""
        UtilityBackend.runFlatpak(newMode, query || "")
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Kirigami.Heading { level: 2; text: qsTr("Applicazioni Flatpak") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.72
                text: qsTr("Ricerca e gestione delle applicazioni Flatpak senza uscire da krisCC.")
            }
        }

        Controls.TabBar {
            id: flatpakTabs
            Layout.fillWidth: true
            currentIndex: root.mode === "installed" ? 1 : root.mode === "updates" ? 2 : root.mode === "remotes" ? 3 : 0
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Cerca"); onClicked: root.mode = "search" }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Installati"); onClicked: root.run("installed", "") }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Aggiornamenti"); onClicked: root.run("updates", "") }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Remote"); onClicked: root.run("remotes", "") }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.mode === "search"
            Controls.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Cerca applicazioni, es. firefox, pdf, inkscape…")
                selectByMouse: true
                onAccepted: if (text.trim().length >= 2) root.run("search", text.trim())
            }
            Controls.Button {
                text: qsTr("Cerca")
                icon.name: "system-search"
                enabled: !UtilityBackend.busy && searchField.text.trim().length >= 2
                onClicked: root.run("search", searchField.text.trim())
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.mode === "remotes"
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Remote configurati per Flatpak.")
            }
            Controls.Button {
                text: qsTr("Aggiungi Flathub")
                icon.name: "list-add"
                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                onClicked: flathubDialog.open()
            }
            Controls.Button {
                text: qsTr("Aggiorna")
                icon.name: "view-refresh"
                enabled: !UtilityBackend.busy
                onClicked: root.run("remotes", "")
            }
        }

        Controls.BusyIndicator {
            visible: UtilityBackend.busy
            running: visible
            Layout.alignment: Qt.AlignHCenter
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !SystemBackend.programAvailable("flatpak")
            type: Kirigami.MessageType.Warning
            text: qsTr("Flatpak non è installato.")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !UtilityBackend.busy && UtilityBackend.output.length > 0 && root.rows().length === 0
            type: Kirigami.MessageType.Information
            text: UtilityBackend.output
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 620)
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: root.rows()

            delegate: Kirigami.AbstractCard {
                required property var modelData
                width: ListView.view.width

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Controls.Label {
                                Layout.fillWidth: true
                                font.bold: true
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                                text: modelData[0] || ""
                                elide: Text.ElideRight
                            }
                            Controls.Label {
                                Layout.fillWidth: true
                                visible: root.mode === "search"
                                text: modelData[1] || ""
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                opacity: 0.82
                            }
                        }

                        Controls.Button {
                            visible: root.mode === "search" && modelData.length >= 3
                            text: qsTr("Installa")
                            icon.name: "list-add"
                            enabled: !UtilityBackend.busy
                            onClicked: root.run("install", modelData[2])
                        }

                        Controls.Button {
                            visible: root.mode === "installed" && modelData.length >= 2
                            text: qsTr("Rimuovi")
                            icon.name: "edit-delete"
                            enabled: !UtilityBackend.busy
                            onClicked: removeDialog.openFor(modelData[1], modelData[0])
                        }
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        opacity: 0.62
                        elide: Text.ElideRight
                        text: {
                            if (root.mode === "search")
                                return [modelData[2], modelData[3], modelData[4], modelData[5]].filter(function(x) { return !!x }).join(" · ")
                            if (root.mode === "installed" || root.mode === "updates")
                                return [modelData[1], modelData[2], modelData[3]].filter(function(x) { return !!x }).join(" · ")
                            return [modelData[1], modelData[2], modelData[3]].filter(function(x) { return !!x }).join(" · ")
                        }
                    }
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: root.mode === "search" && root.lastQuery.length >= 2 && !UtilityBackend.busy && root.rows().length === 0 && UtilityBackend.output.length === 0
            type: Kirigami.MessageType.Information
            text: qsTr("Nessun risultato.")
        }
    }

    Controls.Dialog {
        id: flathubDialog
        modal: true
        title: qsTr("Aggiungere Flathub?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Aggiunge Flathub solo per il tuo utente. Se esiste già, non viene duplicato.")
        }
        onAccepted: {
            UtilityBackend.addFlathubUser()
            root.mode = "remotes"
        }
    }

    Controls.Dialog {
        id: removeDialog
        property string appId: ""
        property string appName: ""
        function openFor(id, name) {
            appId = id
            appName = name
            open()
        }
        modal: true
        title: qsTr("Rimuovere %1?").arg(appName)
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Rimuove il Flatpak %1 dal tuo utente.").arg(removeDialog.appId)
        }
        onAccepted: root.run("remove", appId)
    }
}
