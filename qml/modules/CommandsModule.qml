import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kriscc

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Comandi utili")

    UtilityBackend { id: utilityBackend }

    property var commands: [
        { id: "failed-units", title: qsTr("Unità fallite"), command: "systemctl --failed --no-pager --plain", note: qsTr("Unità systemd in errore.") },
        { id: "journal-errors", title: qsTr("Errori ultimo boot"), command: "journalctl -b -p warning --no-pager -n 200", note: qsTr("Warning ed errori del boot corrente.") },
        { id: "kernel-errors", title: qsTr("Warning kernel"), command: "journalctl -k -b -p warning --no-pager -n 200", note: qsTr("Messaggi kernel rilevanti.") },
        { id: "boot-time", title: qsTr("Tempo di avvio"), command: "systemd-analyze time", note: qsTr("Tempo complessivo di boot.") },
        { id: "blame", title: qsTr("Servizi lenti"), command: "systemd-analyze blame", note: qsTr("Unità ordinate per tempo di avvio.") },
        { id: "uptime", title: qsTr("Uptime"), command: "uptime -p", note: qsTr("Tempo trascorso dall'ultimo boot.") },
        { id: "timers", title: qsTr("Timer systemd"), command: "systemctl list-timers --all --no-pager", note: qsTr("Timer e prossime esecuzioni.") },
        { id: "ports", title: qsTr("Porte in ascolto"), command: "ss -lntu", note: qsTr("Socket TCP/UDP in ascolto.") },
        { id: "network", title: qsTr("Interfacce rete"), command: "ip -brief address", note: qsTr("Interfacce e indirizzi in formato compatto.") },
        { id: "routes", title: qsTr("Route"), command: "ip route", note: qsTr("Tabella di routing corrente.") },
        { id: "dns", title: qsTr("DNS"), command: "resolvectl status", note: qsTr("Resolver e DNS per interfaccia.") },
        { id: "sessions", title: qsTr("Sessioni"), command: "loginctl list-sessions --no-legend", note: qsTr("Sessioni viste da systemd-logind.") },
        { id: "mounts", title: qsTr("Mount attivi"), command: "findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS", note: qsTr("Filesystem montati adesso.") },
        { id: "fstab-order", title: qsTr("Ordine mount"), command: "findmnt --fstab --evaluate -o TARGET,SOURCE,FSTYPE,OPTIONS", note: qsTr("Configurazione persistente dei mount.") },
        { id: "disk-space", title: qsTr("Spazio filesystem"), command: "df -hT -x tmpfs -x devtmpfs", note: qsTr("Utilizzo dei filesystem persistenti.") },
        { id: "partitions", title: qsTr("Partizioni"), command: "lsblk -e 7 -o NAME,PARTN,SIZE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS", note: qsTr("Dischi, partizioni, UUID e mount.") },
        { id: "top-cpu", title: qsTr("Top CPU"), command: "ps -eo pid,comm,%cpu,%mem --sort=-%cpu", note: qsTr("Processi ordinati per CPU.") },
        { id: "top-memory", title: qsTr("Top RAM"), command: "ps -eo pid,comm,%mem,%cpu --sort=-%mem", note: qsTr("Processi ordinati per memoria.") },
        { id: "selinux", title: qsTr("SELinux"), command: "getenforce", note: qsTr("Modalità SELinux attuale.") },
        { id: "rk-status", title: qsTr("Layer RPM"), command: "rk status", note: qsTr("Stato dell'overlay RPM persistente KrisOS.") },
        { id: "flatpak-list", title: qsTr("Flatpak utente"), command: "flatpak list --user --app", note: qsTr("Applicazioni Flatpak del profilo utente.") },
        { id: "podman-images", title: qsTr("Immagini Podman"), command: "podman images", note: qsTr("Immagini container presenti per l'utente.") },
        { id: "uefi", title: qsTr("Voci UEFI"), command: "efibootmgr", note: qsTr("BootCurrent, BootNext e BootOrder.") },
        { id: "grub-entries", title: qsTr("Voci GRUB/BLS"), command: "grubby --info=ALL", note: qsTr("Kernel e voci di avvio conosciute a GRUB.") }
    ]

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Kirigami.Heading { level: 2; font.bold: true; text: qsTr("Comandi comuni") }
            Controls.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                opacity: 0.72
                text: qsTr("Scorciatoie read-only per diagnostica quotidiana. Il comando mostrato è quello eseguito: non c'è una shell libera né input arbitrario.")
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width > 820 ? 2 : 1
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.smallSpacing

            Repeater {
                model: root.commands
                delegate: Kirigami.AbstractCard {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.width > 820
                                           ? (root.width - Kirigami.Units.largeSpacing) / 2
                                           : root.width
                    contentItem: ColumnLayout {
                        spacing: Kirigami.Units.smallSpacing
                        RowLayout {
                            Layout.fillWidth: true
                            Controls.Label { Layout.fillWidth: true; font.bold: true; text: modelData.title }
                            Controls.Button {
                                flat: true
                                icon.name: "edit-copy"
                                display: Controls.AbstractButton.IconOnly
                                onClicked: SystemBackend.copyToClipboard(modelData.command)
                            }
                            Controls.Button {
                                text: qsTr("Esegui")
                                icon.name: "utilities-terminal"
                                enabled: !utilityBackend.busy
                                onClicked: utilityBackend.runBookmark(modelData.id)
                            }
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            font.family: Kirigami.Theme.defaultFixedWidthFont.family
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            opacity: 0.82
                            text: modelData.command
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.72
                            text: modelData.note
                        }
                    }
                }
            }
        }

        Controls.BusyIndicator {
            visible: utilityBackend.busy
            running: visible
            Layout.alignment: Qt.AlignHCenter
        }

        Kirigami.AbstractCard {
            Layout.fillWidth: true
            visible: utilityBackend.title.length > 0 || utilityBackend.output.length > 0
            contentItem: ColumnLayout {
                RowLayout {
                    Layout.fillWidth: true
                    Kirigami.Heading { Layout.fillWidth: true; level: 3; font.bold: true; text: utilityBackend.title || qsTr("Output") }
                    Controls.Button {
                        visible: utilityBackend.busy
                        text: qsTr("Annulla")
                        icon.name: "process-stop"
                        onClicked: utilityBackend.cancel()
                    }
                    Controls.Button {
                        text: qsTr("Copia output")
                        icon.name: "edit-copy"
                        enabled: utilityBackend.output.length > 0
                        onClicked: SystemBackend.copyToClipboard(utilityBackend.output)
                    }
                }
                Controls.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 340
                    readOnly: true
                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                    font.family: Kirigami.Theme.defaultFixedWidthFont.family
                    text: utilityBackend.output
                }
            }
        }
    }
}
