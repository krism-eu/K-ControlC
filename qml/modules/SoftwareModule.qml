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
            root.progressLines = root.progressLines.concat([text]).slice(-10)
        }
        function onFinished(ok, output) {
            root.progressLines = root.progressLines.concat(
                [ok ? "--- completato ---" : "--- FALLITO ---"]).slice(-10)
            BootcBackend.refreshPackages()
            if (searchField.text.trim().length >= 2)
                packageSearch.search(searchField.text)
        }
    }

    Label { text: "Software"; font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { text: "Pacchetti RPM persistenti, lista overlay e applicazioni Flatpak"; font.pixelSize: 12; color: "#94a3b8" }

    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#131c38"; border.color: "#4f46e5"; border.width: 1
        implicitHeight: searchCol.implicitHeight + 28

        ColumnLayout {
            id: searchCol
            anchors.fill: parent; anchors.margins: 14; spacing: 8

            Label { text: "Cerca pacchetti RPM persistenti"; font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "es. btop, krita, lutris…"
                onTextChanged: searchTimer.restart()
            }
            Timer {
                id: searchTimer
                interval: 350
                onTriggered: {
                    root.searchError = ""
                    packageSearch.search(searchField.text)
                }
            }

            BusyIndicator {
                visible: PolkitHelper.running || packageSearch.searching
                running: visible
                Layout.preferredHeight: 24; Layout.preferredWidth: 24
            }

            Label {
                visible: root.searchError.length > 0
                text: root.searchError
                color: "#f87171"; font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 300)
                model: packageSearch
                clip: true
                spacing: 4

                delegate: Rectangle {
                    width: ListView.view.width
                    height: row.implicitHeight + 14
                    radius: 8
                    color: model.owned ? "#111831" : "#1a2450"
                    opacity: model.owned ? 0.60 : 1.0

                    RowLayout {
                        id: row
                        anchors.fill: parent; anchors.margins: 7; spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Label {
                                text: model.name + (model.owned ? "  [base · immutabile]"
                                                    : model.installed ? "  [installato]" : "")
                                color: model.installed ? "#34d399" : "#e0e7ff"
                                font.bold: true; font.pixelSize: 12
                            }
                            Label {
                                text: model.summary; color: "#94a3b8"; font.pixelSize: 11
                                wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        Button {
                            visible: !model.owned
                            enabled: !PolkitHelper.running
                            text: model.installed ? "Rimuovi" : "Installa"
                            onClicked: {
                                root.progressLines = []
                                PolkitHelper.execute("/usr/bin/rk",
                                    model.installed ? ["rm", model.name] : ["add", model.name])
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: ovCol.implicitHeight + 28

        ColumnLayout {
            id: ovCol
            anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: "Pacchetti persistenti (packages.list)"; font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }
            Label {
                text: BootcBackend.persistentPackages
                color: "#94a3b8"; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true
            }
            RowLayout {
                Button {
                    text: "Sincronizza da lista"
                    enabled: !PolkitHelper.running
                    onClicked: { root.progressLines = []; PolkitHelper.execute("/usr/bin/rk", ["sync"]) }
                }
                Button {
                    text: "Modifica lista"
                    onClicked: Qt.openUrlExternally("file:///var/lib/raku-kris/packages.list")
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12; color: "#111831"; border.color: "#253158"
        implicitHeight: fpCol.implicitHeight + 28
        ColumnLayout {
            id: fpCol
            anchors.fill: parent; anchors.margins: 14; spacing: 8
            Label { text: "Flatpak"; font.pixelSize: 14; font.bold: true; color: "#e0e7ff" }
            Label { text: "Le applicazioni sandboxed restano separate dall'immagine di sistema."; font.pixelSize: 12; color: "#94a3b8" }
            Button {
                text: "Apri gestione Flatpak"
                onClicked: PolkitHelper.launchUnprivileged("/usr/bin/kcmshell6", ["kcm_flatpak"])
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.progressLines.length > 0
        radius: 10; color: "#0d152b"; border.color: "#253158"
        implicitHeight: progressCol.implicitHeight + 22
        ColumnLayout {
            id: progressCol
            anchors.fill: parent; anchors.margins: 11; spacing: 2
            Repeater {
                model: root.progressLines
                Label { required property string modelData; text: modelData; color: "#a5b4fc"; font.pixelSize: 10; font.family: "monospace"; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
            }
        }
    }
}
