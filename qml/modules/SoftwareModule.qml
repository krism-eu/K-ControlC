import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kriscc

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Software RPM")
    property bool ownOperation: false
    property var progressLines: []
    property string searchError: ""
    property string listError: ""
    property string installFilter: "all"
    property var detailPackage: null

    function humanSize(bytes) {
        if (!bytes || bytes <= 0)
            return qsTr("non disponibile")
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
            return qsTr("BASE")
        if (model.persistent)
            return qsTr("PERSISTENTE")
        if (model.installed)
            return qsTr("LOCALE")
        return ""
    }

    function visibleForFilter(model) {
        if (root.installFilter === "base") return model.owned
        if (root.installFilter === "persistent") return model.persistent
        if (root.installFilter === "local") return model.installed && !model.owned && !model.persistent
        return true
    }

    function transactionDependencies() {
        if (UtilityBackend.operationId !== "rpm.plan" || UtilityBackend.resultState !== "success")
            return []
        var lines = UtilityBackend.output.split("\n")
        var result = []
        var inDependencies = false
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i]
            var trimmed = line.trim()
            if (trimmed === "Installing dependencies:" || trimmed === "Installing weak dependencies:") {
                inDependencies = true
                continue
            }
            if (inDependencies && (trimmed === "Transaction Summary:" || trimmed.indexOf("Total size of inbound packages") === 0 || trimmed.indexOf("After this operation") === 0))
                inDependencies = false
            if (!inDependencies || !trimmed)
                continue
            if (trimmed.endsWith(":")) {
                inDependencies = false
                continue
            }
            if (trimmed.indexOf("replacing ") === 0)
                continue
            result.push(trimmed)
        }
        return result
    }

    function transactionTotals() {
        if (UtilityBackend.operationId !== "rpm.plan" || UtilityBackend.resultState !== "success")
            return []
        var lines = UtilityBackend.output.split("\n")
        var result = []
        for (var i = 0; i < lines.length; ++i) {
            var trimmed = lines[i].trim()
            if (trimmed.indexOf("Total size of inbound packages") === 0 || trimmed.indexOf("After this operation") === 0)
                result.push(trimmed)
        }
        return result
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

    PackageSearch { id: searchModel; onSearchError: function(message) { root.searchError = message } }
    PackageSearch { id: installedModel; onSearchError: function(message) { root.listError = message } }
    PackageSearch { id: upgradesModel; onSearchError: function(message) { root.listError = message } }
    PackageSearch { id: recentModel; onSearchError: function(message) { root.listError = message } }

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
            spacing: 2
            Kirigami.Heading { level: 2; font.bold: true; text: qsTr("Pacchetti RPM") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.72
                text: qsTr("Base immutabile, pacchetti persistenti gestiti da rk e pacchetti locali vengono distinti chiaramente. La ricerca usa i repository DNF abilitati; l'installazione persistente resta validata dalla policy rk.")
            }
        }

        Controls.TabBar {
            id: tabs
            Layout.fillWidth: true
            onCurrentIndexChanged: root.refreshCurrent()
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Cerca") }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Installati") }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Aggiornabili") }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Novità repository") }
            Controls.TabButton { implicitHeight: Kirigami.Units.gridUnit * 2.1; font.bold: checked; text: qsTr("Repository") }
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
                Kirigami.InlineMessage { Layout.fillWidth: true; visible: root.searchError.length > 0; type: Kirigami.MessageType.Error; text: root.searchError }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 520)
                    model: searchModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        contentItem: ColumnLayout {
                            RowLayout {
                                Layout.fillWidth: true
                                Controls.Label {
                                    Layout.fillWidth: true
                                    font.bold: true
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                                    text: model.name
                                    elide: Text.ElideRight
                                }
                                Controls.Label {
                                    visible: root.packageState(model).length > 0
                                    text: root.packageState(model)
                                    font.bold: true
                                    opacity: 0.7
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
                                text: [model.version, model.arch, model.repository].filter(function(x) { return !!x }).join(" · ")
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Controls.Label { opacity: 0.72; text: qsTr("Download: %1").arg(root.humanSize(model.downloadSize)) }
                                Controls.Label { opacity: 0.72; text: qsTr("Installato: %1").arg(root.humanSize(model.installSize)) }
                                Item { Layout.fillWidth: true }
                                Controls.Button {
                                    text: qsTr("Dettagli")
                                    icon.name: "documentinfo"
                                    onClicked: {
                                        root.detailPackage = {
                                            name: model.name,
                                            summary: model.summary,
                                            version: model.version,
                                            arch: model.arch,
                                            repository: model.repository,
                                            downloadSize: model.downloadSize,
                                            installSize: model.installSize,
                                            state: root.packageState(model)
                                        }
                                        UtilityBackend.previewRpmInstall(model.name)
                                        packageDialog.open()
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
                    Layout.fillWidth: true
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Pacchetti presenti nel sistema, filtrabili per provenienza.") }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: installedModel.loadInstalled() }
                }
                Controls.ButtonGroup { id: installFilterGroup }
                RowLayout {
                    Controls.RadioButton { text: qsTr("Tutti"); checked: true; Controls.ButtonGroup.group: installFilterGroup; onClicked: root.installFilter = "all" }
                    Controls.RadioButton { text: qsTr("Base"); Controls.ButtonGroup.group: installFilterGroup; onClicked: root.installFilter = "base" }
                    Controls.RadioButton { text: qsTr("Persistenti"); Controls.ButtonGroup.group: installFilterGroup; onClicked: root.installFilter = "persistent" }
                    Controls.RadioButton { text: qsTr("Locali"); Controls.ButtonGroup.group: installFilterGroup; onClicked: root.installFilter = "local" }
                    Item { Layout.fillWidth: true }
                }
                Controls.BusyIndicator { visible: installedModel.searching; running: visible; Layout.alignment: Qt.AlignHCenter }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    visible: root.installFilter === "persistent" && !installedModel.searching
                             && BootcBackend.persistentPackageCount === 0
                    type: Kirigami.MessageType.Information
                    text: qsTr("Nessun pacchetto RPM persistente richiesto.")
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 500)
                    model: installedModel
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    delegate: Kirigami.AbstractCard {
                        width: ListView.view.width
                        visible: root.visibleForFilter(model)
                        height: visible ? implicitHeight : 0
                        contentItem: RowLayout {
                            ColumnLayout {
                                Layout.fillWidth: true
                                Controls.Label { Layout.fillWidth: true; font.bold: true; text: model.name + (model.arch ? "." + model.arch : "") }
                                Controls.Label { Layout.fillWidth: true; opacity: 0.65; text: (model.version || "") + (model.repository ? " · " + model.repository : ""); elide: Text.ElideRight }
                            }
                            Controls.Label { text: root.packageState(model); opacity: 0.7; font.bold: model.persistent || model.owned }
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
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Aggiornamenti RPM disponibili nei repository DNF abilitati. La base resta aggiornata tramite BootC.") }
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
            }

            ColumnLayout {
                RowLayout {
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: qsTr("Pacchetti cambiati di recente nei repository DNF abilitati. Non indica la cronologia delle installazioni locali.") }
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
                spacing: Kirigami.Units.smallSpacing
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                    text: qsTr("Repository DNF configurati nel sistema. Puoi aggiungere un file .repo remoto e abilitare o disabilitare repository esistenti. rk continua a validare ogni installazione persistente.")
                }
                RowLayout {
                    Layout.fillWidth: true
                    Controls.Button {
                        text: qsTr("Aggiungi repository")
                        icon.name: "list-add"
                        enabled: !SoftwareBackend.busy && !PolkitHelper.running
                        onClicked: addRepoDialog.open()
                    }
                    Item { Layout.fillWidth: true }
                    Controls.Button { text: qsTr("Aggiorna"); icon.name: "view-refresh"; onClicked: SoftwareBackend.refreshRepositories() }
                }
                Controls.BusyIndicator { visible: SoftwareBackend.busy || PolkitHelper.running; running: visible; Layout.alignment: Qt.AlignHCenter }
                Kirigami.InlineMessage { Layout.fillWidth: true; visible: SoftwareBackend.errorText.length > 0; type: Kirigami.MessageType.Error; text: SoftwareBackend.errorText }

                Repeater {
                    model: SoftwareBackend.repositories
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
                                Layout.preferredWidth: 110
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.enabled ? qsTr("attivo") : qsTr("inattivo")
                                font.bold: true
                                opacity: modelData.enabled ? 1.0 : 0.68
                            }
                            Controls.Button {
                                Layout.preferredWidth: 120
                                enabled: !PolkitHelper.running
                                text: modelData.enabled ? qsTr("Disattiva") : qsTr("Attiva")
                                icon.name: modelData.enabled ? "media-playback-stop" : "media-playback-start"
                                onClicked: root.runPrivileged("/usr/bin/dnf5",
                                    ["config-manager", modelData.enabled ? "disable" : "enable", modelData.id])
                            }
                        }
                    }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: root.progressLines.length > 0
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 3; font.bold: true; text: qsTr("Operazione") }
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
        id: addRepoDialog
        modal: true
        title: qsTr("Aggiungi repository DNF")
        standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
        contentItem: ColumnLayout {
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Inserisci l'URL HTTPS/HTTP di un file .repo. DNF5 ne verificherà la validità prima di salvarlo.")
            }
            Controls.TextField {
                id: repoUrlField
                Layout.fillWidth: true
                placeholderText: qsTr("https://esempio.invalid/repository.repo")
                selectByMouse: true
            }
        }
        onAccepted: {
            var url = repoUrlField.text.trim()
            if (url.length > 0)
                root.runPrivileged("/usr/bin/dnf5",
                    ["config-manager", "addrepo", "--from-repofile=" + url])
            repoUrlField.clear()
        }
        onRejected: repoUrlField.clear()
    }

    Controls.Dialog {
        id: packageDialog
        modal: true
        width: Math.min(root.width - 48, 800)
        title: root.detailPackage ? root.detailPackage.name : qsTr("Dettagli pacchetto")
        standardButtons: Controls.Dialog.Close
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                text: root.detailPackage ? root.detailPackage.summary : ""
            }
            Controls.Label {
                Layout.fillWidth: true
                opacity: 0.7
                wrapMode: Text.WordWrap
                text: root.detailPackage ? [root.detailPackage.version, root.detailPackage.arch, root.detailPackage.repository, root.detailPackage.state].filter(function(x) { return !!x }).join(" · ") : ""
            }

            RowLayout {
                Layout.fillWidth: true
                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Controls.Label { text: qsTr("Download"); opacity: 0.65 }
                        Controls.Label { font.bold: true; text: root.detailPackage ? root.humanSize(root.detailPackage.downloadSize) : "" }
                    }
                }
                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Controls.Label { text: qsTr("Spazio installato"); opacity: 0.65 }
                        Controls.Label { font.bold: true; text: root.detailPackage ? root.humanSize(root.detailPackage.installSize) : "" }
                    }
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }
            Kirigami.Heading { level: 3; font.bold: true; text: qsTr("Piano rk") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.72
                text: qsTr("L'anteprima usa la stessa policy rk dell'installazione reale: repository Fedora supportati, base immutabile protetta e architetture consentite.")
            }
            Controls.BusyIndicator { visible: UtilityBackend.busy; running: visible; Layout.alignment: Qt.AlignHCenter }

            Repeater {
                model: root.transactionTotals()
                delegate: Controls.Label {
                    required property string modelData
                    Layout.fillWidth: true
                    font.bold: true
                    wrapMode: Text.WordWrap
                    text: modelData
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                visible: !UtilityBackend.busy && root.transactionDependencies().length > 0
                contentItem: ColumnLayout {
                    Controls.Label { text: qsTr("Pacchetti aggiuntivi"); font.bold: true }
                    Repeater {
                        model: root.transactionDependencies()
                        delegate: Controls.Label {
                            required property string modelData
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                            text: modelData
                        }
                    }
                }
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                visible: !UtilityBackend.busy && UtilityBackend.operationId === "rpm.plan"
                         && UtilityBackend.resultState !== "idle" && root.transactionDependencies().length === 0
                type: UtilityBackend.resultState === "success" ? Kirigami.MessageType.Information : Kirigami.MessageType.Error
                text: UtilityBackend.resultState === "success"
                    ? qsTr("Il piano rk non segnala dipendenze aggiuntive, oppure il pacchetto è già presente.")
                    : UtilityBackend.output
            }

            Controls.CheckBox {
                id: technicalOutputToggle
                text: qsTr("Mostra output tecnico rk")
            }
            Controls.TextArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                visible: technicalOutputToggle.checked
                readOnly: true
                wrapMode: TextEdit.Wrap
                font.family: "monospace"
                text: UtilityBackend.output
            }
        }
        onClosed: technicalOutputToggle.checked = false
    }
}
