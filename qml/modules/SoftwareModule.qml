import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import raku.cc

ColumnLayout {
    id: root
    spacing: 16

    property var progressLines: []
    property string searchError: ""

    PackageSearch {
        id: packageSearch
        onSearchError: function(message) { root.searchError = message }
    }

    Connections {
        target: PolkitHelper
        function onLine(text) {
            root.progressLines = root.progressLines.concat([text]).slice(-8)
        }
        function onFinished(ok, output) {
            root.progressLines = root.progressLines.concat(
                [ok ? "--- completato ---" : "--- FALLITO ---"]).slice(-8)
        }
    }

    Label { text: "Software"; font.pixelSize: 18; font.bold: true; color: "#e0e7ff" }
    Label { text: "Gestione pacchetti e applicazioni"; font.pixelSize: 12; color: "#6b7280" }

    // ---- Ricerca RPM persistente (overlay rk) ----
    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#1a1a3e"; border.color: "#6366f1"; border.width: 1
        implicitHeight: searchCol.implicitHeight + 24

        ColumnLayout {
            id: searchCol
            anchors.fill: parent; anchors.margins: 16; spacing: 8

            Label { text: "🔍 Cerca pacchetti RPM persistenti"; font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "es. btop, krita, lutris..."
                onTextChanged: searchTimer.restart()
                palette.base: "#252560"; palette.text: "#e0e7ff"
            }
            Timer { id: searchTimer; interval: 350; onTriggered: { root.searchError = ""; packageSearch.search(searchField.text) } }

            BusyIndicator { visible: PolkitHelper.running || packageSearch.searching; running: visible; Layout.preferredHeight: 24; Layout.preferredWidth: 24 }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 260)
                model: packageSearch
                clip: true
                spacing: 4

                delegate: Rectangle {
                    width: ListView.view.width
                    height: row.implicitHeight + 12
                    radius: 8
                    color: model.owned ? "#1a1a3e" : "#252560"
                    opacity: model.owned ? 0.55 : 1.0

                    RowLayout {
                        id: row
                        anchors.fill: parent; anchors.margins: 6; spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Label {
                                text: model.name + (model.owned ? "  [base — immutabile]"
                                                    : model.installed ? "  [installato]" : "")
                                color: model.installed ? "#34d399" : "#e0e7ff"
                                font.bold: true; font.pixelSize: 12
                            }
                            Label {
                                text: model.summary; color: "#6b7280"; font.pixelSize: 11
                                wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        Button {
                            visible: !model.owned
                            enabled: !PolkitHelper.running
                            text: model.installed ? "Rimuovi" : "Installa"
                            palette.button: "#6366f1"; palette.buttonText: "white"
                            onClicked: {
                                root.progressLines = []
                                PolkitHelper.execute("/usr/bin/rk",
                                    model.installed ? ["rm", model.name]
                                                    : ["add", model.name])
                            }
                        }
                    }
                }
            }

            // progress streaming (operazioni lunghe)
            Label {
                visible: root.searchError.length > 0
                text: root.searchError
                color: "#f87171"
                font.pixelSize: 11
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                visible: root.progressLines.length > 0
                spacing: 1
                Repeater {
                    model: root.progressLines
                    Label { text: modelData; color: "#a5b4fc"; font.pixelSize: 10; font.family: "monospace" }
                }
            }
        }
    }

    // ---- Overlay state + sync da lista ----
    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#1a1a3e"; border.color: "#252560"; border.width: 1
        implicitHeight: ovCol.implicitHeight + 24

        ColumnLayout {
            id: ovCol
            anchors.fill: parent; anchors.margins: 16; spacing: 8
            Label { text: "📚 Pacchetti persistenti (packages.list)"; font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }
            Label {
                text: "Persistenti: " + BootcBackend.rkStatus()
                color: "#6b7280"; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true
            }
            RowLayout {
                spacing: 8
                Button {
                    text: "Sincronizza da lista"; palette.button: "#6366f1"; palette.buttonText: "white"
                    enabled: !PolkitHelper.running
                    onClicked: { root.progressLines = []; PolkitHelper.execute("/usr/bin/rk", ["sync"]) }
                }
                Button {
                    text: "Modifica lista"; palette.button: "#1a1a3e"; palette.buttonText: "#a5b4fc"
                    onClicked: Qt.openUrlExternally("file:///var/lib/raku-kris/packages.list")
                }
            }
        }
    }

    // ---- Flatpak (delega a Discover/KCM) ----
    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#1a1a3e"; border.color: "#252560"; border.width: 1
        implicitHeight: fpCol.implicitHeight + 24
        ColumnLayout {
            id: fpCol
            anchors.fill: parent; anchors.margins: 16; spacing: 8
            Label { text: "📦 Flatpak"; font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }
            Label { text: "Applicazioni sandboxed — gestione via Discover o kcmshell6"; font.pixelSize: 12; color: "#6b7280" }
            Button {
                text: "Apri gestione Flatpak"; palette.button: "#1a1a3e"; palette.buttonText: "#a5b4fc"
                onClicked: PolkitHelper.launchUnprivileged("/usr/bin/kcmshell6", ["kcm_flatpak"])
            }
        }
    }
}
