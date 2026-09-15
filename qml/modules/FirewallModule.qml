import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root; spacing: 16; property int refreshToken: 0
    Label { text: qsTr("Sicurezza / Firewall"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { text: qsTr("Controllo firewalld con azioni runtime esplicite. Ogni modifica richiede una nuova autorizzazione Polkit."); color: "#94a3b8"; Layout.fillWidth: true; wrapMode: Text.Wrap }
    Label { text: { root.refreshToken; return qsTr("firewalld: %1").arg(SystemBackend.serviceState("firewalld.service")) }; color: "#e0e7ff"; font.bold: true }
    BusyIndicator { visible: PolkitHelper.running; running: visible }
    GridLayout {
        Layout.fillWidth: true; columns: 3; columnSpacing: 8; rowSpacing: 8
        Button { text: qsTr("Apri SSH"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/firewall-cmd", ["--add-service=ssh"]) }
        Button { text: qsTr("Apri HTTP"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/firewall-cmd", ["--add-service=http"]) }
        Button { text: qsTr("Apri HTTPS"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/firewall-cmd", ["--add-service=https"]) }
        Button { text: qsTr("Chiudi SSH"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/firewall-cmd", ["--remove-service=ssh"]) }
        Button { text: qsTr("Chiudi HTTP"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/firewall-cmd", ["--remove-service=http"]) }
        Button { text: qsTr("Chiudi HTTPS"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/firewall-cmd", ["--remove-service=https"]) }
    }
    RowLayout { Button { text: qsTr("Firewall avanzato"); enabled: SystemBackend.toolAvailable("firewall"); onClicked: SystemBackend.launchTool("firewall") } Button { text: qsTr("Aggiorna stato"); onClicked: root.refreshToken++ } }
    Label { text: qsTr("Le aperture rapide sono runtime-only; le modifiche permanenti restano nell'interfaccia firewalld avanzata."); color: "#64748b"; font.pixelSize: 10; wrapMode: Text.Wrap; Layout.fillWidth: true }
}
