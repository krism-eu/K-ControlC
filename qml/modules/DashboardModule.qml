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

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 1
            text: qsTr("K-ControlC")
        }
        Controls.Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Software persistente, deployment BootC, strumenti pratici e recovery. Le normali impostazioni desktop restano a Plasma.")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !BootcBackend.bootcAvailable
            type: Kirigami.MessageType.Warning
            text: qsTr("bootc non è disponibile in questo ambiente. Le funzioni di deployment saranno disabilitate.")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 720 ? 3 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Sistema") }
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: SystemBackend.osName }
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: SystemBackend.kernelVersion }
                    Controls.Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: SystemBackend.storageSummary }
                    Controls.Button {
                        text: qsTr("Info Center")
                        icon.name: "hwinfo"
                        enabled: SystemBackend.toolAvailable("kinfocenter")
                        onClicked: SystemBackend.launchTool("kinfocenter")
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("BootC") }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: BootcBackend.bootcAvailable ? qsTr("Deployment image-based attivo") : qsTr("bootc non rilevato")
                    }
                    Controls.Button {
                        text: qsTr("Deployment e aggiornamenti")
                        icon.name: "system-software-update"
                        onClicked: root.openRequested("bootc")
                    }
                }
            }

            Kirigami.AbstractCard {
                Layout.fillWidth: true
                contentItem: ColumnLayout {
                    Kirigami.Heading { level: 2; text: qsTr("Pacchetti persistenti") }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("%1 pacchetti gestiti da rk").arg(BootcBackend.persistentPackageCount)
                    }
                    Controls.Button {
                        text: qsTr("Apri Software")
                        icon.name: "system-software-install"
                        onClicked: root.openRequested("software")
                    }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: ColumnLayout {
                Kirigami.Heading { level: 2; text: qsTr("Quick System Info") }
                Controls.TextArea {
                    id: quickInfo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: SystemBackend.quickSystemInfo()
                }
                RowLayout {
                    Controls.Button {
                        text: qsTr("Copia")
                        icon.name: "edit-copy"
                        onClicked: SystemBackend.copyToClipboard(quickInfo.text)
                    }
                    Controls.Button {
                        text: qsTr("Strumenti")
                        icon.name: "applications-utilities"
                        onClicked: root.openRequested("tools")
                    }
                    Controls.Button {
                        text: qsTr("Recovery / backup")
                        icon.name: "document-save-all"
                        onClicked: root.openRequested("recovery")
                    }
                }
            }
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            contentItem: RowLayout {
                Controls.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Rete, utenti, firewall, display, audio e le altre preferenze desktop sono già gestite da Plasma.")
                }
                Controls.Button {
                    text: qsTr("Impostazioni Plasma")
                    icon.name: "settings-configure"
                    enabled: SystemBackend.toolAvailable("systemsettings")
                    onClicked: SystemBackend.launchTool("systemsettings")
                }
            }
        }
    }
}
