import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Panoramica")
    signal openRequested(string pageId)

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Kirigami.Heading { level: 1; text: qsTr("krisCC") }
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    opacity: 0.72
                    text: qsTr("Controllo essenziale di KrisOS senza duplicare le Impostazioni di sistema Plasma.")
                }
            }
            Controls.Button {
                text: qsTr("Sistema")
                icon.name: "preferences-system"
                onClicked: root.openRequested("system")
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !BootcBackend.bootcAvailable
            type: Kirigami.MessageType.Warning
            text: qsTr("bootc non è disponibile in questo ambiente. Le funzioni image-based sono disabilitate.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 760 ? 2 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Sistema") }
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: SystemBackend.osName }
                    Controls.Label { Layout.fillWidth: true; opacity: 0.7; text: SystemBackend.kernelVersion }
                    Controls.Label { Layout.fillWidth: true; opacity: 0.7; text: SystemBackend.storageSummary }
                    RowLayout {
                        Controls.Button { text: qsTr("Salute"); icon.name: "tools-report-bug"; onClicked: root.openRequested("system") }
                        Controls.Button { text: qsTr("Info Center"); icon.name: "hwinfo"; enabled: SystemBackend.toolAvailable("kinfocenter"); onClicked: SystemBackend.launchTool("kinfocenter") }
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Aggiornamenti") }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: BootcBackend.bootcAvailable ? qsTr("KrisOS image-based attivo") : qsTr("BootC non rilevato")
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        opacity: 0.7
                        text: qsTr("%1 pacchetti RPM persistenti").arg(BootcBackend.persistentPackageCount)
                    }
                    Controls.Button {
                        text: qsTr("Apri centro aggiornamenti")
                        icon.name: "system-software-update"
                        onClicked: root.openRequested("system")
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Software") }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("RPM persistenti tramite rk e applicazioni Flatpak utente.")
                    }
                    RowLayout {
                        Controls.Button { text: qsTr("RPM"); icon.name: "system-software-install"; onClicked: root.openRequested("software") }
                        Controls.Button { text: qsTr("Flatpak"); icon.name: "package-x-generic"; onClicked: root.openRequested("flatpak") }
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Container") }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: SystemBackend.programAvailable("podman") ? qsTr("Podman disponibile per l'utente corrente") : qsTr("Podman non installato")
                    }
                    Controls.Button {
                        text: qsTr("Apri Container")
                        icon.name: "package-x-generic"
                        enabled: SystemBackend.programAvailable("podman")
                        onClicked: root.openRequested("podman")
                    }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading { Layout.fillWidth: true; level: 2; text: qsTr("Quick System Info") }
                    Controls.Button {
                        text: qsTr("Copia")
                        icon.name: "edit-copy"
                        onClicked: SystemBackend.copyToClipboard(quickInfo.text)
                    }
                }
                Controls.TextArea {
                    id: quickInfo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: SystemBackend.quickSystemInfo()
                }
                RowLayout {
                    Controls.Button { text: qsTr("Comandi utili"); icon.name: "utilities-terminal"; onClicked: root.openRequested("commands") }
                    Controls.Button { text: qsTr("Backup / recovery"); icon.name: "document-save-all"; onClicked: root.openRequested("recovery") }
                    Item { Layout.fillWidth: true }
                    Controls.Button { text: qsTr("Impostazioni Plasma"); icon.name: "settings-configure"; enabled: SystemBackend.toolAvailable("systemsettings"); onClicked: SystemBackend.launchTool("systemsettings") }
                }
            }
        }
    }
}
