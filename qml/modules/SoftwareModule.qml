import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import raku.cc

ColumnLayout {
    id: root
    spacing: 16
    property var progressLines: []
    property string searchError: ""

    PackageSearch { id: packageSearch; onSearchError: function(message) { root.searchError = message } }
    Connections {
        target: PolkitHelper
        function onLine(text) { root.progressLines = root.progressLines.concat([text]).slice(-10) }
        function onFinished(ok, output) {
            root.progressLines = root.progressLines.concat([ok ? qsTr("--- completato ---") : qsTr("--- FALLITO ---")]).slice(-10)
            BootcBackend.refreshPackages()
            if (searchField.text.trim().length >= 2) packageSearch.search(searchField.text)
        }
    }

    Label { text: qsTr("Software"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { text: qsTr("Pacchetti RPM persistenti gestiti da rk e applicazioni Flatpak separate dall'immagine."); color: "#94a3b8"; wrapMode: Text.Wrap; Layout.fillWidth: true }

    Rectangle {
        Layout.fillWidth: true; radius: 12; color: "#131c38"; border.color: "#4f46e5"; implicitHeight: searchCol.implicitHeight + 28
        ColumnLayout {
            id: searchCol; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Cerca per nome pacchetto"); font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }
            TextField { id: searchField; Layout.fillWidth: true; placeholderText: qsTr("es. btop, krita, lutris…"); onTextChanged: searchTimer.restart() }
            Timer { id: searchTimer; interval: 350; onTriggered: { root.searchError = ""; packageSearch.search(searchField.text) } }
            BusyIndicator { visible: PolkitHelper.running || packageSearch.searching; running: visible; Layout.preferredHeight: 24; Layout.preferredWidth: 24 }
            Label { visible: root.searchError.length > 0; text: root.searchError; color: "#f87171"; font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true }
            ListView {
                Layout.fillWidth: true; Layout.preferredHeight: Math.min(contentHeight, 310); model: packageSearch; clip: true; spacing: 4
                delegate: Rectangle {
                    width: ListView.view.width; height: row.implicitHeight + 14; radius: 8; color: model.owned ? "#111831" : "#1a2450"; opacity: model.owned ? 0.60 : 1.0
                    RowLayout { id: row; anchors.fill: parent; anchors.margins: 7; spacing: 8
                        ColumnLayout { Layout.fillWidth: true; spacing: 1
                            Label { text: model.name + (model.owned ? qsTr("  [base · immutabile]") : model.installed ? qsTr("  [installato]") : ""); color: model.installed ? "#34d399" : "#e0e7ff"; font.bold: true; font.pixelSize: 12 }
                            Label { text: model.summary; color: "#94a3b8"; font.pixelSize: 11; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        Button { visible: !model.owned; enabled: !PolkitHelper.running; text: model.installed ? qsTr("Rimuovi") : qsTr("Installa"); onClicked: { root.progressLines = []; PolkitHelper.execute("/usr/bin/rk", model.installed ? ["rm", model.name] : ["add", model.name]) } }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; radius: 12; color: "#111831"; border.color: "#253158"; implicitHeight: pkgCol.implicitHeight + 28
        ColumnLayout { id: pkgCol; anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: qsTr("Pacchetti persistenti"); font.bold: true; color: "#e0e7ff" }
            Label { text: BootcBackend.persistentPackages; color: "#94a3b8"; wrapMode: Text.Wrap; Layout.fillWidth: true }
            RowLayout { Button { text: qsTr("Sincronizza lista"); enabled: !PolkitHelper.running; onClicked: PolkitHelper.execute("/usr/bin/rk", ["sync"]) } Button { text: qsTr("Gestione Flatpak"); onClicked: SystemBackend.launchFlatpakManager() } }
        }
    }

    Rectangle {
        Layout.fillWidth: true; visible: root.progressLines.length > 0; radius: 10; color: "#0d152b"; border.color: "#253158"; implicitHeight: progressCol.implicitHeight + 22
        ColumnLayout { id: progressCol; anchors.fill: parent; anchors.margins: 11; spacing: 2
            Repeater { model: root.progressLines; Label { required property string modelData; text: modelData; color: "#a5b4fc"; font.pixelSize: 10; font.family: "monospace"; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true } }
        }
    }
}
