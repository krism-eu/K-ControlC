import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    spacing: 16
    Label { text: qsTr("Utenti"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: qsTr("Gestione account tramite il modulo utenti di Plasma, che usa i propri controlli di autorizzazione."); color: "#94a3b8"; wrapMode: Text.Wrap }
    Rectangle { Layout.fillWidth: true; radius: 12; color: "#131c38"; border.color: "#293761"; implicitHeight: col.implicitHeight + 30
        ColumnLayout { id: col; anchors.fill: parent; anchors.margins: 15; spacing: 10
            Label { text: qsTr("Account locali"); font.bold: true; color: "#e0e7ff" }
            Label { Layout.fillWidth: true; text: qsTr("Aggiunta, rimozione, gruppi e password restano delegate al KCM utenti invece di costruire comandi useradd/usermod da QML."); color: "#94a3b8"; wrapMode: Text.Wrap }
            Button { text: qsTr("Apri gestione utenti"); onClicked: if (!SystemBackend.launchKcm("kcm_users")) SystemBackend.launchTool("systemsettings") }
        }
    }
}
