import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Comandi utili")

    property var commands: [
        { id: "failed-units", title: qsTr("Unità fallite"), note: qsTr("Mostra solo unità systemd in errore.") },
        { id: "timers", title: qsTr("Timer systemd"), note: qsTr("Elenca timer pianificati e prossime esecuzioni.") },
        { id: "ports", title: qsTr("Porte in ascolto"), note: qsTr("Socket TCP/UDP in ascolto, senza privilegi root.") },
        { id: "sessions", title: qsTr("Sessioni attive"), note: qsTr("Sessioni utente viste da systemd-logind.") },
        { id: "mounts", title: qsTr("Mount attivi"), note: qsTr("Filesystem e mount correnti.") },
        { id: "top-cpu", title: qsTr("Processi per CPU"), note: qsTr("Processi ordinati per utilizzo CPU.") },
        { id: "top-memory", title: qsTr("Processi per memoria"), note: qsTr("Processi ordinati per utilizzo RAM.") },
        { id: "selinux", title: qsTr("Stato SELinux"), note: qsTr("Modalità SELinux attuale.") }
    ]

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading { level: 2; text: qsTr("Bookmark amministrativi") }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.78
            text: qsTr("Comandi informativi che non sono già coperti dalle altre pagine. Non è una shell libera: ogni comando è predefinito e non modifica il sistema.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 760 ? 2 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: root.commands
                delegate: Kirigami.AbstractCard {
                    required property var modelData
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        ColumnLayout {
                            Layout.fillWidth: true
                            Controls.Label { font.bold: true; text: modelData.title }
                            Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: 0.68; text: modelData.note }
                        }
                        Controls.Button {
                            text: qsTr("Esegui")
                            icon.name: "utilities-terminal"
                            enabled: !UtilityBackend.busy
                            onClicked: UtilityBackend.runBookmark(modelData.id)
                        }
                    }
                }
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
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading { Layout.fillWidth: true; level: 3; text: UtilityBackend.title || qsTr("Output") }
                    Controls.Button {
                        visible: UtilityBackend.busy
                        text: qsTr("Annulla")
                        icon.name: "process-stop"
                        onClicked: UtilityBackend.cancel()
                    }
                    Controls.Button {
                        text: qsTr("Copia")
                        icon.name: "edit-copy"
                        enabled: UtilityBackend.output.length > 0
                        onClicked: SystemBackend.copyToClipboard(UtilityBackend.output)
                    }
                }
                Controls.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 320
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: UtilityBackend.output
                }
            }
        }
    }
}
