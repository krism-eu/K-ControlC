import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    id: root
    title: qsTr("Comandi utili")

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
            Kirigami.Heading { level: 2; text: qsTr("Comandi comuni") }
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
                                enabled: !UtilityBackend.busy
                                onClicked: UtilityBackend.runBookmark(modelData.id)
                            }
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            font.family: "monospace"
                            wrapMode: Text.WrapAnywhere
                            opacity: 0.82
                            text: modelData.command
                        }
                        Controls.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: 0.62
                            text: modelData.note
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
                        text: qsTr("Copia output")
                        icon.name: "edit-copy"
                        enabled: UtilityBackend.output.length > 0
                        onClicked: SystemBackend.copyToClipboard(UtilityBackend.output)
                    }
                }
                Controls.TextArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 340
                    readOnly: true
                    wrapMode: TextEdit.WrapAnywhere
                    font.family: "monospace"
                    text: UtilityBackend.output
                }
            }
        }
    }
}
