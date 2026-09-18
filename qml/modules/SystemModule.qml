import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Sistema")

    property bool ownBootAction: false
    property string bootActionKind: ""
    property string historyText: ""

    function runBootc(args) {
        PolkitHelper.execute("/usr/bin/bootc", args)
    }

    function uefiEntries() {
        if (UtilityBackend.operationId !== "bookmark.uefi" || UtilityBackend.resultState !== "success")
            return []
        var result = []
        var lines = UtilityBackend.output.split("\n")
        for (var i = 0; i < lines.length; ++i) {
            var match = lines[i].match(/^Boot([0-9A-Fa-f]{4})\*?\s+(.+)$/)
            if (match)
                result.push({ code: match[1].toUpperCase(), label: match[1].toUpperCase() + " · " + match[2] })
        }
        return result
    }

    function grubEntries() {
        if (UtilityBackend.operationId !== "bookmark.grub-entries" || UtilityBackend.resultState !== "success")
            return []
        var result = []
        var current = {}
        var lines = UtilityBackend.output.split("\n")
        function commit() {
            if (current.id) {
                var label = current.title ? current.title : current.id
                result.push({ id: current.id, label: label })
            }
            current = {}
        }
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()
            if (line.indexOf("index=") === 0) {
                commit()
            } else if (line.indexOf("title=") === 0) {
                current.title = line.substring(6).replace(/^"|"$/g, "")
            } else if (line.indexOf("id=") === 0) {
                current.id = line.substring(3).replace(/^"|"$/g, "")
            }
        }
        commit()
        return result
    }

    Component.onCompleted: {
        root.historyText = SystemBackend.operationHistory()
        BootcBackend.refreshStatus()
    }

    Connections {
        target: PolkitHelper
        function onFinished(success, output) {
            if (!root.ownBootAction)
                return
            root.ownBootAction = false
            if (root.bootActionKind === "uefi")
                UtilityBackend.runBookmark("uefi")
            else if (root.bootActionKind === "grub")
                UtilityBackend.runBookmark("grub-entries")
            root.historyText = SystemBackend.operationHistory()
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Kirigami.Heading { level: 2; text: qsTr("KrisOS") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.72
                text: qsTr("Aggiornamenti, salute, avvio e strumenti essenziali. Le normali preferenze desktop restano nelle Impostazioni di sistema Plasma.")
            }
        }

        Controls.TabBar {
            id: sections
            Layout.fillWidth: true
            Controls.TabButton { text: qsTr("Aggiornamenti") }
            Controls.TabButton { text: qsTr("Salute") }
            Controls.TabButton { text: qsTr("Avvio e dischi") }
            Controls.TabButton { text: qsTr("Strumenti") }
        }

        StackLayout {
            Layout.fillWidth: true
            currentIndex: sections.currentIndex

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing
                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Heading { Layout.fillWidth: true; level: 2; text: qsTr("KrisOS / BootC") }
                            Controls.BusyIndicator { visible: BootcBackend.busy || PolkitHelper.running; running: visible }
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: BootcBackend.bootcAvailable
                                  ? qsTr("Immagine di sistema gestita da BootC.")
                                  : qsTr("BootC non disponibile.")
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            opacity: 0.68
                            text: qsTr("%1 pacchetti RPM persistenti richiesti").arg(BootcBackend.persistentPackageCount)
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Controls.Button {
                                text: qsTr("Controlla immagine")
                                icon.name: "view-refresh"
                                enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                                onClicked: root.runBootc(["upgrade", "--check"])
                            }
                            Controls.Button {
                                text: qsTr("Scarica")
                                icon.name: "download"
                                enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                                onClicked: root.runBootc(["upgrade", "--download-only"])
                            }
                            Controls.Button {
                                text: qsTr("Prepara aggiornamento")
                                icon.name: "system-software-update"
                                enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                                onClicked: root.runBootc(["upgrade"])
                            }
                            Controls.Button {
                                text: qsTr("Applica")
                                icon.name: "system-reboot"
                                enabled: BootcBackend.bootcAvailable && !PolkitHelper.running
                                onClicked: applyDialog.open()
                            }
                            Controls.Button {
                                text: qsTr("Risincronizza RPM")
                                icon.name: "view-refresh"
                                enabled: !PolkitHelper.running && SystemBackend.programAvailable("rk")
                                onClicked: syncDialog.open()
                            }
                        }
                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            readOnly: true
                            wrapMode: TextEdit.WrapAnywhere
                            font.family: "monospace"
                            text: BootcBackend.statusText
                        }
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Heading { Layout.fillWidth: true; level: 2; text: qsTr("Flatpak") }
                            Controls.BusyIndicator { visible: UtilityBackend.busy; running: visible }
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.72
                            text: qsTr("Controllo e aggiornamento delle applicazioni Flatpak del profilo utente.")
                        }
                        RowLayout {
                            Controls.Button {
                                text: qsTr("Controlla")
                                icon.name: "view-refresh"
                                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                                onClicked: UtilityBackend.runFlatpak("updates", "")
                            }
                            Controls.Button {
                                text: qsTr("Aggiorna tutto")
                                icon.name: "system-software-update"
                                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                                onClicked: flatpakDialog.open()
                            }
                        }
                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 130
                            visible: UtilityBackend.operationId.indexOf("flatpak.") === 0
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
                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Heading { Layout.fillWidth: true; level: 2; text: qsTr("Cronologia") }
                            Controls.Button {
                                text: qsTr("Aggiorna")
                                icon.name: "view-refresh"
                                onClicked: root.historyText = SystemBackend.operationHistory()
                            }
                            Controls.Button {
                                text: qsTr("Pulisci")
                                icon.name: "edit-clear-history"
                                enabled: root.historyText.length > 0
                                onClicked: clearHistoryDialog.open()
                            }
                        }
                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 190
                            readOnly: true
                            wrapMode: TextEdit.WrapAnywhere
                            font.family: "monospace"
                            text: root.historyText.length > 0 ? root.historyText : qsTr("Nessuna operazione registrata.")
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Kirigami.Heading { level: 2; text: qsTr("Salute del sistema") }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.72
                            text: qsTr("Controlli leggibili e non distruttivi su unità fallite, overlay /usr, spazio, rk e stato BootC.")
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Controls.Button { text: qsTr("Controlla salute"); icon.name: "tools-report-bug"; enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("health") }
                            Controls.Button { text: qsTr("Sicurezza"); icon.name: "security-high"; enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("security") }
                            Controls.Button { text: qsTr("Unità fallite"); icon.name: "dialog-warning"; enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("failed-units") }
                            Controls.Button { text: qsTr("Errori ultimo avvio"); icon.name: "view-list-text"; enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("journal-errors") }
                        }
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    type: Kirigami.MessageType.Information
                    text: qsTr("krisCC mostra lo stato disponibile ma non modifica Secure Boot, SELinux o firewall da questa pagina.")
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    visible: UtilityBackend.operationId === "bookmark.health"
                          || UtilityBackend.operationId === "bookmark.security"
                          || UtilityBackend.operationId === "bookmark.failed-units"
                          || UtilityBackend.operationId === "bookmark.journal-errors"
                    contentItem: ColumnLayout {
                        RowLayout {
                            Layout.fillWidth: true
                            Kirigami.Heading { Layout.fillWidth: true; level: 3; text: UtilityBackend.title }
                            Controls.Button {
                                text: qsTr("Copia")
                                icon.name: "edit-copy"
                                enabled: UtilityBackend.output.length > 0
                                onClicked: SystemBackend.copyToClipboard(UtilityBackend.output)
                            }
                        }
                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 330
                            readOnly: true
                            wrapMode: TextEdit.WrapAnywhere
                            font.family: "monospace"
                            text: UtilityBackend.output
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Kirigami.Heading { level: 2; text: qsTr("Prossimo avvio UEFI") }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.72
                            text: qsTr("BootNext vale per un solo riavvio e non cambia il BootOrder permanente.")
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Button {
                                text: qsTr("Leggi voci UEFI")
                                icon.name: "view-refresh"
                                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("efibootmgr")
                                onClicked: UtilityBackend.runBookmark("uefi")
                            }
                            Controls.ComboBox {
                                id: uefiCombo
                                Layout.fillWidth: true
                                model: root.uefiEntries()
                                textRole: "label"
                                valueRole: "code"
                                enabled: count > 0
                            }
                            Controls.Button {
                                text: qsTr("Usa al prossimo avvio")
                                enabled: uefiCombo.count > 0 && !PolkitHelper.running
                                onClicked: {
                                    nextUefiDialog.token = uefiCombo.currentValue
                                    nextUefiDialog.label = uefiCombo.currentText
                                    nextUefiDialog.open()
                                }
                            }
                        }
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Kirigami.Heading { level: 2; text: qsTr("Voci GRUB / BLS") }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.72
                            text: qsTr("Le voci vengono lette da grubby. Se grub2-reboot è disponibile puoi scegliere una voce solo per il prossimo avvio.")
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Button {
                                text: qsTr("Leggi voci")
                                icon.name: "view-refresh"
                                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("grubby")
                                onClicked: UtilityBackend.runBookmark("grub-entries")
                            }
                            Controls.ComboBox {
                                id: grubCombo
                                Layout.fillWidth: true
                                model: root.grubEntries()
                                textRole: "label"
                                valueRole: "id"
                                enabled: count > 0
                            }
                            Controls.Button {
                                text: qsTr("Prossimo avvio")
                                enabled: grubCombo.count > 0 && SystemBackend.programAvailable("grub2-reboot") && !PolkitHelper.running
                                onClicked: {
                                    nextGrubDialog.entryId = grubCombo.currentValue
                                    nextGrubDialog.label = grubCombo.currentText
                                    nextGrubDialog.open()
                                }
                            }
                        }
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    contentItem: ColumnLayout {
                        Kirigami.Heading { level: 2; text: qsTr("Partizioni e ordine mount") }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.72
                            text: qsTr("Vista read-only di partizioni, mount correnti e configurazione persistente. krisCC non riscrive fstab automaticamente.")
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Controls.Button { text: qsTr("Partizioni"); enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("partitions") }
                            Controls.Button { text: qsTr("Ordine mount"); enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("fstab-order") }
                            Controls.Button { text: qsTr("Mount attivi"); enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("mounts") }
                            Controls.Button { text: qsTr("Spazio"); enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("disk-space") }
                            Controls.Button {
                                text: qsTr("Partition Manager")
                                icon.name: "partitionmanager"
                                enabled: SystemBackend.toolAvailable("partitionmanager")
                                onClicked: SystemBackend.launchTool("partitionmanager")
                            }
                        }
                    }
                }

                Kirigami.AbstractCard {
                    Layout.fillWidth: true
                    visible: UtilityBackend.operationId === "bookmark.uefi"
                          || UtilityBackend.operationId === "bookmark.grub-entries"
                          || UtilityBackend.operationId === "bookmark.partitions"
                          || UtilityBackend.operationId === "bookmark.fstab-order"
                          || UtilityBackend.operationId === "bookmark.mounts"
                          || UtilityBackend.operationId === "bookmark.disk-space"
                    contentItem: ColumnLayout {
                        Kirigami.Heading { level: 3; text: UtilityBackend.title }
                        Controls.TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            readOnly: true
                            wrapMode: TextEdit.WrapAnywhere
                            font.family: "monospace"
                            text: UtilityBackend.output
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 760 ? 2 : 1
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.largeSpacing

                    Kirigami.AbstractCard {
                        Layout.fillWidth: true
                        contentItem: ColumnLayout {
                            Kirigami.Heading { level: 2; text: qsTr("Plasma") }
                            Controls.Button { text: qsTr("Impostazioni di sistema"); icon.name: "settings-configure"; enabled: SystemBackend.toolAvailable("systemsettings"); onClicked: SystemBackend.launchTool("systemsettings") }
                            Controls.Button { text: qsTr("Info Center"); icon.name: "hwinfo"; enabled: SystemBackend.toolAvailable("kinfocenter"); onClicked: SystemBackend.launchTool("kinfocenter") }
                        }
                    }

                    Kirigami.AbstractCard {
                        Layout.fillWidth: true
                        contentItem: ColumnLayout {
                            Kirigami.Heading { level: 2; text: qsTr("Diagnostica") }
                            Controls.Button { text: qsTr("KSystemLog"); icon.name: "utilities-log-viewer"; enabled: SystemBackend.toolAvailable("ksystemlog"); onClicked: SystemBackend.launchTool("ksystemlog") }
                            Controls.Button { text: qsTr("Monitor di sistema"); icon.name: "utilities-system-monitor"; enabled: SystemBackend.toolAvailable("systemmonitor"); onClicked: SystemBackend.launchTool("systemmonitor") }
                        }
                    }

                    Kirigami.AbstractCard {
                        Layout.fillWidth: true
                        contentItem: ColumnLayout {
                            Kirigami.Heading { level: 2; text: qsTr("Pulizia") }
                            Controls.Button { text: qsTr("Flatpak inutilizzati"); enabled: SystemBackend.programAvailable("flatpak") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("flatpak-unused") }
                            Controls.Button { text: qsTr("RPM non necessari"); enabled: SystemBackend.programAvailable("dnf5") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("unneeded") }
                        }
                    }

                    Kirigami.AbstractCard {
                        Layout.fillWidth: true
                        contentItem: ColumnLayout {
                            Kirigami.Heading { level: 2; text: qsTr("Storage") }
                            Controls.Button { text: qsTr("Dischi in terminale"); enabled: SystemBackend.programAvailable("lsblk") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("disks") }
                            Controls.Button { text: qsTr("Partition Manager"); enabled: SystemBackend.toolAvailable("partitionmanager"); onClicked: SystemBackend.launchTool("partitionmanager") }
                        }
                    }
                }
            }
        }
    }

    Controls.Dialog {
        id: applyDialog
        modal: true
        title: qsTr("Applicare l'aggiornamento KrisOS?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("BootC applicherà l'immagine preparata. Potrebbe essere necessario riavviare.")
        }
        onAccepted: root.runBootc(["upgrade", "--apply"])
    }

    Controls.Dialog {
        id: syncDialog
        modal: true
        title: qsTr("Risincronizzare i pacchetti persistenti?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Esegue rk sync sul layer persistente corrente. Non modifica la lista dei pacchetti richiesti.")
        }
        onAccepted: PolkitHelper.execute("/usr/bin/rk", ["sync"])
    }

    Controls.Dialog {
        id: flatpakDialog
        modal: true
        title: qsTr("Aggiornare tutti i Flatpak utente?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: UtilityBackend.runFlatpak("update-all", "")
    }

    Controls.Dialog {
        id: clearHistoryDialog
        modal: true
        title: qsTr("Cancellare la cronologia krisCC?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        onAccepted: {
            SystemBackend.clearOperationHistory()
            root.historyText = SystemBackend.operationHistory()
        }
    }

    Controls.Dialog {
        id: nextUefiDialog
        property string token: ""
        property string label: ""
        modal: true
        title: qsTr("Usare questa voce al prossimo avvio?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label { wrapMode: Text.WordWrap; text: nextUefiDialog.label }
        onAccepted: {
            root.ownBootAction = true
            root.bootActionKind = "uefi"
            PolkitHelper.execute("/usr/bin/efibootmgr", ["-n", nextUefiDialog.token])
        }
    }

    Controls.Dialog {
        id: nextGrubDialog
        property string entryId: ""
        property string label: ""
        modal: true
        title: qsTr("Usare questa voce GRUB al prossimo avvio?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label { wrapMode: Text.WordWrap; text: nextGrubDialog.label }
        onAccepted: {
            root.ownBootAction = true
            root.bootActionKind = "grub"
            PolkitHelper.execute("/usr/bin/grub2-reboot", [nextGrubDialog.entryId])
        }
    }
}
