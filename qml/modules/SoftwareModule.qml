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

        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Gestione del layer RPM persistente e consultazione DNF5. Gli aggiornamenti della base immutabile restano nella pagina BootC; Flatpak e applicazioni grafiche possono essere gestiti separatamente.")
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
                Controls.BusyIndicator { visible: searchModel.searching; running: visible }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.searchError.length > 0
                    type: Kirigami.MessageType.Error
                    text: root.searchError
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 460)
                    model: searchModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Controls.ItemDelegate {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label {
                                    Layout.fillWidth: true
                                    font.bold: true
                                    text: model.name
                                          + (model.owned ? qsTr("  [base]")
                                             : model.persistent ? qsTr("  [persistente]")
                                             : model.installed ? qsTr("  [installato]") : "")
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    text: model.summary
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    opacity: 0.7
                                    elide: Text.ElideRight
                                    text: {
                                        var parts = []
                                        if (model.version) parts.push(model.version)
                                        if (model.arch) parts.push(model.arch)
                                        if (model.repository) parts.push(model.repository)
                                        if (model.downloadSize > 0) parts.push(qsTr("download %1").arg(root.humanSize(model.downloadSize)))
                                        if (model.installSize > 0) parts.push(qsTr("installato %1").arg(root.humanSize(model.installSize)))
                                        return parts.join(" · ")
                                    }
                                }
                            }
                            Controls.Button {
                                visible: model.persistent || (!model.installed && !model.owned)
                                enabled: !PolkitHelper.running
                                text: model.persistent ? qsTr("Rimuovi") : qsTr("Installa")
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
                Controls.BusyIndicator { visible: installedModel.searching; running: visible }
                RowLayout {
                    Controls.Label { Layout.fillWidth: true; text: qsTr("Pacchetti RPM presenti nel sistema. Solo quelli nella lista persistente sono rimovibili da qui."); wrapMode: Text.WordWrap }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: installedModel.loadInstalled() }
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 480)
                    model: installedModel
                    clip: true
                    delegate: Controls.ItemDelegate {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
                                Controls.Label { Layout.fillWidth: true; text: (model.version || "") + (model.repository ? " · " + model.repository : ""); elide: Text.ElideRight }
                            }
                            Controls.Label { text: model.owned ? qsTr("base") : model.persistent ? qsTr("persistente") : qsTr("sistema") }
                            Controls.Button {
                                visible: model.persistent
                                enabled: !PolkitHelper.running
                                text: qsTr("Rimuovi")
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
                        text: qsTr("Versioni più recenti viste dai repository DNF5. Questo pannello è informativo: la base si aggiorna con BootC e il layer persistente con rk.")
                    }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: upgradesModel.loadUpgrades() }
                }
                Controls.BusyIndicator { visible: upgradesModel.searching; running: visible }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 480)
                    model: upgradesModel
                    clip: true
                    delegate: Controls.ItemDelegate {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
                            Controls.Label { text: model.version || "" }
                            Controls.Label { text: model.repository || "" }
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
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Pacchetti cambiati di recente nei repository configurati, secondo la finestra recent di DNF5.") }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: recentModel.loadRecent() }
                }
                Controls.BusyIndicator { visible: recentModel.searching; running: visible }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 480)
                    model: recentModel
                    clip: true
                    delegate: Controls.ItemDelegate {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
                            Controls.Label { text: model.version || "" }
                            Controls.Label { text: model.repository || "" }
                        }
                    }
                }
            }

            ColumnLayout {
                RowLayout {
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Repository DNF5 configurati. Quelli abilitati sono mostrati per primi; i disabilitati restano visibili ma attenuati.")
                    }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: SoftwareBackend.refreshRepositories() }
                }
                Controls.BusyIndicator { visible: SoftwareBackend.busy; running: visible }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: SoftwareBackend.errorText.length > 0
                    type: Kirigami.MessageType.Error
                    text: SoftwareBackend.errorText
                }
                Repeater {
                    model: SoftwareBackend.repositories
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        opacity: modelData.enabled ? 1.0 : 0.58
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { font.bold: true; text: modelData.name }
                                Controls.Label { text: modelData.id; opacity: 0.7 }
                            }
                            Controls.Label {
                                font.bold: modelData.enabled
                                text: modelData.enabled ? qsTr("ABILITATO") : qsTr("disabilitato")
                            }
                            Controls.Button {
                                enabled: !PolkitHelper.running
                                text: modelData.enabled ? qsTr("Disabilita") : qsTr("Abilita")
                                onClicked: root.runPrivileged("/usr/bin/dnf5", ["config-manager", modelData.enabled ? "disable" : "enable", modelData.id])
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
                          ? qsTr("Discover è disponibile per applicazioni grafiche e Flatpak. La gestione Flatpak essenziale potrà essere integrata direttamente qui senza dipendere da Discover.")
                          : qsTr("Discover non è installato. Flatpak è indipendente da Discover: la gestione essenziale verrà integrata direttamente in K-ControlC.")
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
