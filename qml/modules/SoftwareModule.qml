import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kcontrolc

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Software")
    property bool ownOperation: false
    property var progressLines: []
    property string searchError: ""
    property string listError: ""

    function humanSize(bytes) {
        if (!bytes || bytes <= 0)
            return ""
        if (bytes >= 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GiB"
        if (bytes >= 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MiB"
        if (bytes >= 1024)
            return (bytes / 1024).toFixed(1) + " KiB"
        return bytes + " B"
    }

    function packageState(model) {
        if (model.owned)
            return qsTr("base")
        if (model.persistent)
            return qsTr("persistente")
        if (model.installed)
            return qsTr("installato")
        return ""
    }

    function runPrivileged(program, args) {
        root.ownOperation = true
        root.progressLines = []
        PolkitHelper.execute(program, args)
    }

    function refreshCurrent() {
        root.listError = ""
        if (tabs.currentIndex === 1) installedModel.loadInstalled()
        else if (tabs.currentIndex === 2) upgradesModel.loadUpgrades()
        else if (tabs.currentIndex === 3) recentModel.loadRecent()
        else if (tabs.currentIndex === 4) SoftwareBackend.refreshRepositories()
    }

    Component.onCompleted: SoftwareBackend.refreshRepositories()

    PackageSearch {
        id: searchModel
        onSearchError: function(message) { root.searchError = message }
    }
    PackageSearch {
        id: installedModel
        onSearchError: function(message) { root.listError = message }
    }
    PackageSearch {
        id: upgradesModel
        onSearchError: function(message) { root.listError = message }
    }
    PackageSearch {
        id: recentModel
        onSearchError: function(message) { root.listError = message }
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
            BootcBackend.refreshPackages()
            SoftwareBackend.refreshRepositories()
            if (searchField.text.trim().length >= 2)
                searchModel.search(searchField.text)
            root.refreshCurrent()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Heading {
                level: 2
                text: qsTr("Software persistente")
            }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.78
                text: qsTr("Pacchetti RPM persistenti e consultazione DNF5. La base immutabile resta gestita da BootC; Flatpak rimane indipendente dal layer RPM.")
            }
        }

        Controls.TabBar {
            id: tabs
            Layout.fillWidth: true
            onCurrentIndexChanged: root.refreshCurrent()
            Controls.TabButton { text: qsTr("Cerca") }
            Controls.TabButton { text: qsTr("Installati") }
            Controls.TabButton { text: qsTr("Aggiornabili") }
            Controls.TabButton { text: qsTr("Recenti") }
            Controls.TabButton { text: qsTr("Repository") }
            Controls.TabButton { text: qsTr("Discover") }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: root.listError.length > 0
            type: Kirigami.MessageType.Error
            text: root.listError
        }

        StackLayout {
            Layout.fillWidth: true
            currentIndex: tabs.currentIndex

            ColumnLayout {
                spacing: Kirigami.Units.smallSpacing

                Controls.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Cerca un pacchetto, es. btop, krita, lutris…")
                    selectByMouse: true
                    onTextChanged: searchTimer.restart()
                }
                Timer {
                    id: searchTimer
                    interval: 350
                    onTriggered: {
                        root.searchError = ""
                        searchModel.search(searchField.text)
                    }
                }
                Controls.BusyIndicator {
                    visible: searchModel.searching
                    running: visible
                    Layout.alignment: Qt.AlignHCenter
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.searchError.length > 0
                    type: Kirigami.MessageType.Error
                    text: root.searchError
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 520)
                    model: searchModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing

                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing

                                    Controls.Label {
                                        Layout.fillWidth: true
                                        font.bold: true
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                                        elide: Text.ElideRight
                                        text: model.name
                                    }
                                    Controls.Label {
                                        visible: root.packageState(model).length > 0
                                        text: root.packageState(model)
                                        font.bold: true
                                        opacity: 0.68
                                    }
                                }

                                Controls.Label {
                                    Layout.fillWidth: true
                                    visible: model.summary.length > 0
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    text: model.summary
                                }

                                Controls.Label {
                                    Layout.fillWidth: true
                                    opacity: 0.62
                                    elide: Text.ElideRight
                                    text: {
                                        var parts = []
                                        if (model.version) parts.push(model.version)
                                        if (model.arch) parts.push(model.arch)
                                        if (model.repository) parts.push(model.repository)
                                        return parts.join(" · ")
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: model.downloadSize > 0 || model.installSize > 0
                                    spacing: Kirigami.Units.largeSpacing

                                    Controls.Label {
                                        visible: model.downloadSize > 0
                                        opacity: 0.72
                                        text: qsTr("Download: %1").arg(root.humanSize(model.downloadSize))
                                    }
                                    Controls.Label {
                                        visible: model.installSize > 0
                                        opacity: 0.72
                                        text: qsTr("Installato: %1").arg(root.humanSize(model.installSize))
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }

                            Controls.Button {
                                visible: model.persistent || (!model.installed && !model.owned)
                                enabled: !PolkitHelper.running
                                text: model.persistent ? qsTr("Rimuovi") : qsTr("Installa")
                                icon.name: model.persistent ? "edit-delete" : "list-add"
                                onClicked: root.runPrivileged("/usr/bin/rk", model.persistent ? ["rm", model.name] : ["add", model.name])
                            }
                        }
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: searchField.text.trim().length >= 2 && !searchModel.searching && searchModel.count === 0
                    type: Kirigami.MessageType.Information
                    text: qsTr("Nessun risultato.")
                }
            }

            ColumnLayout {
                RowLayout {
                    Controls.Label {
                        Layout.fillWidth: true
                        text: qsTr("Pacchetti RPM presenti nel sistema. Solo quelli nella lista persistente sono rimovibili da qui.")
                        wrapMode: Text.WordWrap
                    }
                    Controls.Button {
                        text: qsTr("Aggiorna")
                        icon.name: "view-refresh"
                        onClicked: installedModel.loadInstalled()
                    }
                }
                Controls.BusyIndicator {
                    visible: installedModel.searching
                    running: visible
                    Layout.alignment: Qt.AlignHCenter
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: installedModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label {
                                    Layout.fillWidth: true
                                    font.bold: true
                                    text: model.name + (model.arch ? "." + model.arch : "")
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    opacity: 0.65
                                    text: (model.version || "") + (model.repository ? " · " + model.repository : "")
                                    elide: Text.ElideRight
                                }
                            }
                            Controls.Label {
                                text: model.owned ? qsTr("base") : model.persistent ? qsTr("persistente") : qsTr("sistema")
                                opacity: 0.7
                                font.bold: model.persistent
                            }
                            Controls.Button {
                                visible: model.persistent
                                enabled: !PolkitHelper.running
                                text: qsTr("Rimuovi")
                                icon.name: "edit-delete"
                                onClicked: root.runPrivileged("/usr/bin/rk", ["rm", model.name])
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                RowLayout {
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Versioni più recenti viste dai repository DNF5. La base si aggiorna con BootC e il layer persistente con rk.")
                    }
                    Controls.Button {
                        text: qsTr("Aggiorna")
                        icon.name: "view-refresh"
                        onClicked: upgradesModel.loadUpgrades()
                    }
                }
                Controls.BusyIndicator {
                    visible: upgradesModel.searching
                    running: visible
                    Layout.alignment: Qt.AlignHCenter
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: upgradesModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Controls.Label {
                                Layout.fillWidth: true
                                font.bold: true
                                text: model.name + (model.arch ? "." + model.arch : "")
                            }
                            Controls.Label { text: model.version || ""; opacity: 0.72 }
                            Controls.Label { text: model.repository || ""; opacity: 0.62 }
                        }
                    }
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: !upgradesModel.searching && upgradesModel.count === 0 && root.listError.length === 0
                    type: Kirigami.MessageType.Positive
                    text: qsTr("Nessun aggiornamento RPM segnalato dai repository.")
                }
            }

            ColumnLayout {
                RowLayout {
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Pacchetti cambiati di recente nei repository configurati, secondo la finestra recent di DNF5.")
                    }
                    Controls.Button {
                        text: qsTr("Aggiorna")
                        icon.name: "view-refresh"
                        onClicked: recentModel.loadRecent()
                    }
                }
                Controls.BusyIndicator {
                    visible: recentModel.searching
                    running: visible
                    Layout.alignment: Qt.AlignHCenter
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: recentModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Controls.Label {
                                Layout.fillWidth: true
                                font.bold: true
                                text: model.name + (model.arch ? "." + model.arch : "")
                            }
                            Controls.Label { text: model.version || ""; opacity: 0.72 }
                            Controls.Label { text: model.repository || ""; opacity: 0.62 }
                        }
                    }
                }
            }

            ColumnLayout {
                RowLayout {
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Repository DNF5 configurati. Gli abilitati sono separati dai repository disponibili ma inattivi.")
                    }
                    Controls.Button {
                        text: qsTr("Aggiorna")
                        icon.name: "view-refresh"
                        onClicked: SoftwareBackend.refreshRepositories()
                    }
                }
                Controls.BusyIndicator {
                    visible: SoftwareBackend.busy
                    running: visible
                    Layout.alignment: Qt.AlignHCenter
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: SoftwareBackend.errorText.length > 0
                    type: Kirigami.MessageType.Error
                    text: SoftwareBackend.errorText
                }

                Kirigami.Heading {
                    level: 3
                    text: qsTr("Abilitati")
                }
                Repeater {
                    model: SoftwareBackend.repositories.filter(function(repo) { return repo.enabled })
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { font.bold: true; text: modelData.name }
                                Controls.Label { text: modelData.id; opacity: 0.62 }
                            }
                            Controls.Label {
                                text: qsTr("attivo")
                                font.bold: true
                            }
                            Controls.Button {
                                enabled: !PolkitHelper.running
                                text: qsTr("Disabilita")
                                onClicked: root.runPrivileged("/usr/bin/dnf5", ["config-manager", "disable", modelData.id])
                            }
                        }
                    }
                }

                Kirigami.Heading {
                    level: 3
                    text: qsTr("Disabilitati")
                    opacity: 0.72
                }
                Repeater {
                    model: SoftwareBackend.repositories.filter(function(repo) { return !repo.enabled })
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        opacity: 0.62
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { font.bold: true; text: modelData.name }
                                Controls.Label { text: modelData.id; opacity: 0.62 }
                            }
                            Controls.Label { text: qsTr("inattivo") }
                            Controls.Button {
                                enabled: !PolkitHelper.running
                                text: qsTr("Abilita")
                                onClicked: root.runPrivileged("/usr/bin/dnf5", ["config-manager", "enable", modelData.id])
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Heading { level: 2; text: qsTr("Applicazioni e Flatpak") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: SystemBackend.toolAvailable("discover")
                          ? qsTr("Discover è disponibile. La gestione Flatpak essenziale verrà integrata direttamente in K-ControlC senza dipendere da Discover.")
                          : qsTr("Discover non è installato. Flatpak è comunque disponibile e verrà gestito direttamente da K-ControlC.")
                }
                Controls.Button {
                    visible: SystemBackend.toolAvailable("discover")
                    text: qsTr("Apri Discover")
                    icon.name: "plasmadiscover"
                    onClicked: SystemBackend.launchFlatpakManager()
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
}
