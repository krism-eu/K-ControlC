import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kcontrolc

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Software RPM")
    property bool ownOperation: false
    property var progressLines: []
    property string searchError: ""
    property string listError: ""
    property string selectedName: ""
    property string selectedSummary: ""
    property string selectedMeta: ""
    property string selectedSizes: ""

    function humanSize(bytes) {
        if (!bytes || bytes <= 0) return ""
        if (bytes >= 1024 * 1024 * 1024) return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GiB"
        if (bytes >= 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MiB"
        if (bytes >= 1024) return (bytes / 1024).toFixed(1) + " KiB"
        return bytes + " B"
    }

    function packageState(model) {
        if (model.owned) return qsTr("BASE")
        if (model.persistent) return qsTr("PERSISTENTE")
        if (model.installed) return qsTr("LOCALE")
        return ""
    }

    function isAdvancedRepo(id) {
        var s = (id || "").toLowerCase()
        return s.indexOf("debuginfo") >= 0 || s.indexOf("-source") >= 0
            || s.indexOf("testing") >= 0 || s.indexOf("archive") >= 0
    }

    function runPrivileged(program, args) {
        root.ownOperation = true
        root.progressLines = []
        PolkitHelper.execute(program, args)
    }

    function openDetails(name, summary, version, arch, repository, downloadSize, installSize) {
        root.selectedName = name
        root.selectedSummary = summary || ""
        var meta = []
        if (version) meta.push(version)
        if (arch) meta.push(arch)
        if (repository) meta.push(repository)
        root.selectedMeta = meta.join(" · ")
        var sizes = []
        if (downloadSize > 0) sizes.push(qsTr("Download %1").arg(root.humanSize(downloadSize)))
        if (installSize > 0) sizes.push(qsTr("Installato %1").arg(root.humanSize(installSize)))
        root.selectedSizes = sizes.join(" · ")
        UtilityBackend.previewRpmInstall(name)
        detailsDialog.open()
    }

    function refreshCurrent() {
        root.listError = ""
        if (tabs.currentIndex === 1) installedModel.loadInstalled()
        else if (tabs.currentIndex === 2) upgradesModel.loadUpgrades()
        else if (tabs.currentIndex === 3) recentModel.loadRecent()
        else if (tabs.currentIndex === 4) SoftwareBackend.refreshRepositories()
    }

    Component.onCompleted: SoftwareBackend.refreshRepositories()

    PackageSearch { id: searchModel; onSearchError: function(message) { root.searchError = message } }
    PackageSearch { id: installedModel; onSearchError: function(message) { root.listError = message } }
    PackageSearch { id: upgradesModel; onSearchError: function(message) { root.listError = message } }
    PackageSearch { id: recentModel; onSearchError: function(message) { root.listError = message } }

    Connections {
        target: PolkitHelper
        function onLine(text) {
            if (root.ownOperation) root.progressLines = root.progressLines.concat([text]).slice(-12)
        }
        function onFinished(ok, output) {
            if (!root.ownOperation) return
            root.ownOperation = false
            root.progressLines = root.progressLines.concat([ok ? qsTr("--- completato ---") : qsTr("--- fallito ---")]).slice(-12)
            BootcBackend.refreshPackages()
            SoftwareBackend.refreshRepositories()
            if (searchField.text.trim().length >= 2) searchModel.search(searchField.text)
            root.refreshCurrent()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading { level: 2; text: qsTr("Software RPM") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                    text: qsTr("La base BootC resta separata. I pacchetti aggiunti qui passano da rk e sono evidenziati come persistenti.")
                }
            }
        }

        Controls.TabBar {
            id: tabs
            Layout.fillWidth: true
            onCurrentIndexChanged: root.refreshCurrent()
            Controls.TabButton { text: qsTr("Cerca") }
            Controls.TabButton { text: qsTr("Installati") }
            Controls.TabButton { text: qsTr("Aggiornamenti") }
            Controls.TabButton { text: qsTr("Recenti") }
            Controls.TabButton { text: qsTr("Repository") }
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
                Controls.BusyIndicator { visible: searchModel.searching; running: visible; Layout.alignment: Qt.AlignHCenter }
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
                                    Controls.Label { Layout.fillWidth: true; font.bold: true; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1; elide: Text.ElideRight; text: model.name }
                                    Controls.Label { visible: root.packageState(model).length > 0; text: root.packageState(model); font.bold: true; opacity: 0.68 }
                                }
                                Controls.Label { Layout.fillWidth: true; visible: model.summary.length > 0; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: model.summary }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    opacity: 0.62
                                    elide: Text.ElideRight
                                    text: [model.version, model.arch, model.repository].filter(function(v) { return v }).join(" · ")
                                }
                                Controls.Label {
                                    Layout.fillWidth: true
                                    opacity: 0.72
                                    visible: model.downloadSize > 0 || model.installSize > 0
                                    text: (model.downloadSize > 0 ? qsTr("Download %1").arg(root.humanSize(model.downloadSize)) : "")
                                          + (model.downloadSize > 0 && model.installSize > 0 ? " · " : "")
                                          + (model.installSize > 0 ? qsTr("Installato %1").arg(root.humanSize(model.installSize)) : "")
                                }
                            }
                            ColumnLayout {
                                Controls.Button {
                                    text: qsTr("Dettagli")
                                    icon.name: "documentinfo"
                                    onClicked: root.openDetails(model.name, model.summary, model.version, model.arch, model.repository, model.downloadSize, model.installSize)
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
                }
            }

            ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    Controls.ComboBox {
                        id: installedFilter
                        model: [qsTr("Tutti"), qsTr("Base"), qsTr("Persistenti"), qsTr("Locali")]
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        opacity: 0.7
                        text: qsTr("Base = immagine; Persistenti = gestiti da rk; Locali = presenti ma non appartenenti alle prime due categorie.")
                    }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: installedModel.loadInstalled() }
                }
                Controls.BusyIndicator { visible: installedModel.searching; running: visible; Layout.alignment: Qt.AlignHCenter }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: installedModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        property bool matchFilter: installedFilter.currentIndex === 0
                                                   || (installedFilter.currentIndex === 1 && model.owned)
                                                   || (installedFilter.currentIndex === 2 && model.persistent)
                                                   || (installedFilter.currentIndex === 3 && !model.owned && !model.persistent)
                        visible: matchFilter
                        height: matchFilter ? 66 : 0
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
                                Controls.Label { Layout.fillWidth: true; opacity: 0.62; elide: Text.ElideRight; text: (model.version || "") + (model.repository ? " · " + model.repository : "") }
                            }
                            Controls.Label { font.bold: true; opacity: 0.72; text: root.packageState(model) }
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
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Aggiornamenti RPM disponibili. La base immutabile continua a essere aggiornata dalla pagina BootC.") }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: upgradesModel.loadUpgrades() }
                }
                Controls.BusyIndicator { visible: upgradesModel.searching; running: visible; Layout.alignment: Qt.AlignHCenter }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: upgradesModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
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
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Pacchetti cambiati di recente nei repository configurati.") }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: recentModel.loadRecent() }
                }
                Controls.BusyIndicator { visible: recentModel.searching; running: visible; Layout.alignment: Qt.AlignHCenter }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: recentModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
                            Controls.Label { text: model.version || ""; opacity: 0.72 }
                            Controls.Label { text: model.repository || ""; opacity: 0.62 }
                        }
                    }
                }
            }

            ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    Controls.Button { text: qsTr("Aggiungi repository…"); icon.name: "list-add"; onClicked: addRepoDialog.open() }
                    Controls.CheckBox { id: showAdvanced; text: qsTr("Mostra debug/source/testing/archive") }
                    Item { Layout.fillWidth: true }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: SoftwareBackend.refreshRepositories() }
                }
                Controls.BusyIndicator { visible: SoftwareBackend.busy; running: visible; Layout.alignment: Qt.AlignHCenter }
                Kirigami.InlineMessage { Layout.fillWidth: true; visible: SoftwareBackend.errorText.length > 0; type: Kirigami.MessageType.Error; text: SoftwareBackend.errorText }

                Kirigami.Heading { level: 3; text: qsTr("Abilitati") }
                Repeater {
                    model: SoftwareBackend.repositories.filter(function(repo) { return repo.enabled && (showAdvanced.checked || !root.isAdvancedRepo(repo.id)) })
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        contentItem: RowLayout {
                            ColumnLayout { Layout.fillWidth: true; Controls.Label { font.bold: true; text: modelData.name }; Controls.Label { text: modelData.id; opacity: 0.62 } }
                            Controls.Label { text: qsTr("attivo"); font.bold: true }
                            Controls.Button { Layout.preferredWidth: 120; enabled: !PolkitHelper.running; text: qsTr("Disabilita"); onClicked: root.runPrivileged("/usr/bin/dnf5", ["config-manager", "disable", modelData.id]) }
                        }
                    }
                }

                Kirigami.Heading { level: 3; text: qsTr("Disabilitati"); opacity: 0.72 }
                Repeater {
                    model: SoftwareBackend.repositories.filter(function(repo) { return !repo.enabled && (showAdvanced.checked || !root.isAdvancedRepo(repo.id)) })
                    delegate: Kirigami.AbstractCard {
                        required property var modelData
                        Layout.fillWidth: true
                        opacity: 0.68
                        contentItem: RowLayout {
                            ColumnLayout { Layout.fillWidth: true; Controls.Label { font.bold: true; text: modelData.name }; Controls.Label { text: modelData.id; opacity: 0.62 } }
                            Controls.Label { text: qsTr("inattivo") }
                            Controls.Button { Layout.preferredWidth: 120; enabled: !PolkitHelper.running; text: qsTr("Abilita"); onClicked: root.runPrivileged("/usr/bin/dnf5", ["config-manager", "enable", modelData.id]) }
                        }
                    }
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
        id: detailsDialog
        modal: true
        width: Math.min(root.width * 0.82, 760)
        height: Math.min(root.height * 0.82, 620)
        title: root.selectedName
        standardButtons: Controls.Dialog.Close
        contentItem: ColumnLayout {
            Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: root.selectedSummary }
            Controls.Label { Layout.fillWidth: true; opacity: 0.68; text: root.selectedMeta }
            Controls.Label { Layout.fillWidth: true; opacity: 0.72; text: root.selectedSizes }
            Kirigami.Heading { level: 3; text: qsTr("Anteprima transazione") }
            Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.68; text: qsTr("DNF5 risolve la transazione con --assumeno: qui vedi anche dipendenze e spazio totale senza installare nulla.") }
            Controls.BusyIndicator { visible: UtilityBackend.busy; running: visible; Layout.alignment: Qt.AlignHCenter }
            Controls.TextArea { Layout.fillWidth: true; Layout.fillHeight: true; readOnly: true; wrapMode: TextEdit.WrapAnywhere; font.family: "monospace"; text: UtilityBackend.output }
        }
    }

    Controls.Dialog {
        id: addRepoDialog
        modal: true
        title: qsTr("Aggiungi repository DNF5")
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        contentItem: ColumnLayout {
            Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Inserisci un URL HTTPS che punti a un file .repo. DNF5 lo convalida prima di salvarlo.") }
            Controls.TextField { id: repoUrl; Layout.fillWidth: true; placeholderText: "https://example.org/example.repo"; selectByMouse: true }
        }
        onAccepted: {
            var u = repoUrl.text.trim()
            if (u.length > 0) root.runPrivileged("/usr/bin/dnf5", ["config-manager", "addrepo", "--from-repofile=" + u])
        }
    }
}
