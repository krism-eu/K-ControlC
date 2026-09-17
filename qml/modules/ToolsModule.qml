import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Strumenti")
    property int refreshToken: 0
    property var services: [
        { id: "NetworkManager.service", title: qsTr("NetworkManager") },
        { id: "cups.service", title: qsTr("Stampa (CUPS)") },
        { id: "bluetooth.service", title: qsTr("Bluetooth") }
    ]

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.78
            text: qsTr("Azioni pratiche e collegamenti a strumenti KDE già installati. Se un'app esterna non è presente nella base, il relativo pulsante resta disabilitato.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 760 ? 2 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Pulizia") }
                    Controls.Button { text: qsTr("Flatpak inutilizzati"); icon.name: "edit-clear-history"; enabled: SystemBackend.programAvailable("flatpak") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("flatpak-unused") }
                    Controls.Button { text: qsTr("Trova RPM non necessari"); icon.name: "system-search"; enabled: SystemBackend.programAvailable("dnf5") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("unneeded") }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Diagnostica") }
                    Controls.Button { text: qsTr("Warning/errori ultimo boot"); icon.name: "view-list-text"; enabled: SystemBackend.programAvailable("journalctl") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("journal-errors") }
                    Controls.Button { text: SystemBackend.toolAvailable("ksystemlog") ? qsTr("KSystemLog") : qsTr("KSystemLog · non installato"); icon.name: "utilities-log-viewer"; enabled: SystemBackend.toolAvailable("ksystemlog"); onClicked: SystemBackend.launchTool("ksystemlog") }
                    Controls.Button { text: qsTr("Info Center"); icon.name: "hwinfo"; enabled: SystemBackend.toolAvailable("kinfocenter"); onClicked: SystemBackend.launchTool("kinfocenter") }
                    Controls.Button { text: SystemBackend.toolAvailable("systemmonitor") ? qsTr("Monitor di sistema") : qsTr("Monitor di sistema · non installato"); icon.name: "utilities-system-monitor"; enabled: SystemBackend.toolAvailable("systemmonitor"); onClicked: SystemBackend.launchTool("systemmonitor") }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Hardware e storage") }
                    Controls.Button { text: qsTr("Dischi e filesystem"); icon.name: "drive-harddisk"; enabled: SystemBackend.programAvailable("lsblk") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("disks") }
                    Controls.Button { text: SystemBackend.toolAvailable("partitionmanager") ? qsTr("Partition Manager") : qsTr("Partition Manager · non installato"); icon.name: "partitionmanager"; enabled: SystemBackend.toolAvailable("partitionmanager"); onClicked: SystemBackend.launchTool("partitionmanager") }
                    Controls.Button { text: qsTr("Controlla firmware"); icon.name: "cpu"; enabled: SystemBackend.programAvailable("fwupdmgr") && SystemBackend.toolAvailable("konsole"); onClicked: SystemBackend.launchQuickAction("firmware") }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Plasma") }
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.72; text: qsTr("Le impostazioni desktop restano nei pannelli Plasma per evitare duplicazioni.") }
                    Controls.Button { text: qsTr("Impostazioni di sistema"); icon.name: "settings-configure"; enabled: SystemBackend.toolAvailable("systemsettings"); onClicked: SystemBackend.launchTool("systemsettings") }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Servizi rapidi") }
                Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.72; text: qsTr("Restano intenzionalmente solo tre servizi riavviabili da qui.") }
                Repeater {
                    model: root.services
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Controls.Label { Layout.fillWidth: true; font.bold: true; text: modelData.title }
                        Controls.Label { text: { root.refreshToken; return SystemBackend.serviceState(modelData.id) } }
                        Controls.Button { Layout.preferredWidth: 110; text: qsTr("Riavvia"); onClicked: SystemBackend.restartService(modelData.id) }
                    }
                }
                RowLayout {
                    Controls.Button { text: qsTr("Aggiorna stati"); icon.name: "view-refresh"; onClicked: root.refreshToken++ }
                    Controls.Button { text: qsTr("Mostra tutti gli attivi"); icon.name: "view-list-details"; enabled: !UtilityBackend.busy; onClicked: UtilityBackend.runBookmark("services-active") }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: UtilityBackend.operationId === "bookmark.services-active"
                  && UtilityBackend.resultState !== "idle"
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 3; text: UtilityBackend.title }
                Controls.TextArea { Layout.fillWidth: true; Layout.preferredHeight: 260; readOnly: true; wrapMode: TextEdit.WrapAnywhere; font.family: "monospace"; text: UtilityBackend.output }
            }
        }
    }
}
