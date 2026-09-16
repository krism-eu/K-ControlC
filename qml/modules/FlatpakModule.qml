import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Flatpak")

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Heading { level: 2; text: qsTr("Applicazioni Flatpak") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.78
                text: qsTr("Gestione Flatpak separata dagli RPM. Le operazioni qui non modificano la base BootC.")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Controls.Button {
                text: qsTr("Installati")
                icon.name: "view-list-details"
                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                onClicked: UtilityBackend.runFlatpak("installed")
            }
            Controls.Button {
                text: qsTr("Aggiornamenti")
                icon.name: "system-software-update"
                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                onClicked: UtilityBackend.runFlatpak("updates")
            }
            Controls.Button {
                text: qsTr("Remote")
                icon.name: "network-server"
                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                onClicked: UtilityBackend.runFlatpak("remotes")
            }
            Item { Layout.fillWidth: true }
            Controls.Button {
                text: qsTr("Aggiungi Flathub (utente)")
                icon.name: "list-add"
                enabled: !UtilityBackend.busy && SystemBackend.programAvailable("flatpak")
                onClicked: flathubDialog.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Controls.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Cerca su Flatpak, es. firefox, inkscape…")
                selectByMouse: true
                onAccepted: if (text.trim().length >= 2) UtilityBackend.runFlatpak("search", text)
            }
            Controls.Button {
                text: qsTr("Cerca")
                icon.name: "system-search"
                enabled: !UtilityBackend.busy && searchField.text.trim().length >= 2
                onClicked: UtilityBackend.runFlatpak("search", searchField.text)
            }
        }

        Controls.BusyIndicator {
            visible: UtilityBackend.busy
            running: visible
            Layout.alignment: Qt.AlignHCenter
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: UtilityBackend.title.length > 0 || UtilityBackend.output.length > 0
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 3; text: UtilityBackend.title || qsTr("Risultato") }
                Controls.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: UtilityBackend.output
                }
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: qsTr("Flathub viene aggiunto come remote dell'utente, quindi senza password amministrativa e senza modificare la base del sistema.")
        }
    }

    Controls.Dialog {
        id: flathubDialog
        modal: true
        title: qsTr("Aggiungere Flathub?")
        standardButtons: Controls.Dialog.Yes | Controls.Dialog.No
        contentItem: Controls.Label {
            wrapMode: Text.WordWrap
            text: qsTr("Aggiunge il remote Flathub solo per il tuo utente. Se esiste già, non viene duplicato.")
        }
        onAccepted: UtilityBackend.addFlathubUser()
    }
}
