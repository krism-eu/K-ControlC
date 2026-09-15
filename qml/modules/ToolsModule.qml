import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import raku.cc

ColumnLayout {
    id: root
    spacing: 16
    property string externalSearch: ""
    signal openPage(int index)
    readonly property string effectiveQuery: (externalSearch.trim().length > 0 ? externalSearch : localSearch.text).trim().toLowerCase()
    property var modules: [
        { index: 0, title: qsTr("Panoramica"), description: qsTr("Stato rapido del sistema") },
        { index: 1, title: qsTr("Software"), description: qsTr("Pacchetti RPM persistenti e Flatpak") },
        { index: 2, title: qsTr("Deployment"), description: qsTr("Aggiornamenti BootC e rollback") },
        { index: 3, title: qsTr("Sistema"), description: qsTr("Data, ora, NTP e sessione") },
        { index: 4, title: qsTr("Rete"), description: qsTr("NetworkManager e connettività") },
        { index: 5, title: qsTr("Utenti"), description: qsTr("Account e gestione utenti") },
        { index: 6, title: qsTr("Servizi"), description: qsTr("NetworkManager, CUPS e Bluetooth") },
        { index: 7, title: qsTr("Hardware"), description: qsTr("Dispositivi e informazioni hardware") },
        { index: 8, title: qsTr("Storage"), description: qsTr("Dischi, partizioni e spazio") },
        { index: 9, title: qsTr("Firewall"), description: qsTr("firewalld e porte comuni") },
        { index: 10, title: qsTr("Diagnostica"), description: qsTr("Log e Quick System Info") },
        { index: 11, title: qsTr("Firmware"), description: qsTr("fwupd e aggiornamenti firmware") },
        { index: 12, title: qsTr("Recovery"), description: qsTr("Rollback e strumenti di recupero") }
    ]

    PackageSearch {
        id: packageSearch
    }

    onExternalSearchChanged: searchTimer.restart()

    Timer {
        id: searchTimer
        interval: 400
        onTriggered: packageSearch.search(root.effectiveQuery)
    }

    Label { text: qsTr("Strumenti e ricerca globale"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label {
        Layout.fillWidth: true
        text: qsTr("Cerca moduli K-ControlC, applicazioni di amministrazione installate e pacchetti RPM.")
        color: "#94a3b8"; wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.fillWidth: true
        TextField {
            id: localSearch
            Layout.fillWidth: true
            placeholderText: root.externalSearch.length > 0 ? root.externalSearch : qsTr("Cerca…")
            enabled: root.externalSearch.length === 0
            onTextChanged: searchTimer.restart()
        }
        ComboBox {
            id: categoryFilter
            model: [qsTr("Tutti"), qsTr("Sistema"), qsTr("Rete"), qsTr("Sicurezza"), qsTr("Hardware")]
            Layout.preferredWidth: 170
        }
        BusyIndicator {
            visible: packageSearch.searching
            running: visible
            Layout.preferredWidth: 24; Layout.preferredHeight: 24
        }
    }

    Flow {
        id: moduleFlow
        Layout.fillWidth: true
        spacing: 8
        visible: root.effectiveQuery.length > 0
        Repeater {
            model: root.modules
            delegate: Button {
                required property var modelData
                visible: modelData.title.toLowerCase().includes(root.effectiveQuery)
                      || modelData.description.toLowerCase().includes(root.effectiveQuery)
                text: modelData.title + " · " + modelData.description
                onClicked: root.openPage(modelData.index)
            }
        }
    }

    Label { text: qsTr("Utility installate"); font.bold: true; color: "#c7d2fe"; font.pixelSize: 15 }

    Flow {
        id: flow
        Layout.fillWidth: true
        spacing: 12
        Repeater {
            model: SystemBackend.tools
            delegate: ToolCard {
                required property var modelData
                width: flow.width >= 900 ? (flow.width - 24) / 3 : (flow.width >= 600 ? (flow.width - 12) / 2 : flow.width)
                visible: (categoryFilter.currentIndex === 0 || modelData.category === categoryFilter.currentText)
                      && (root.effectiveQuery.length === 0
                          || modelData.title.toLowerCase().includes(root.effectiveQuery)
                          || modelData.description.toLowerCase().includes(root.effectiveQuery)
                          || modelData.category.toLowerCase().includes(root.effectiveQuery))
                title: modelData.title
                description: modelData.description.length > 0 ? modelData.description : modelData.category
                glyph: "◆"
                available: true
                onLaunchRequested: SystemBackend.launchTool(modelData.toolId)
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.effectiveQuery.length >= 2
        spacing: 8
        Label { text: qsTr("Pacchetti RPM"); font.bold: true; color: "#c7d2fe"; font.pixelSize: 15 }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 260)
            model: packageSearch
            clip: true
            spacing: 4
            delegate: Rectangle {
                width: ListView.view.width
                height: packageRow.implicitHeight + 12
                radius: 8; color: "#131c38"
                RowLayout {
                    id: packageRow
                    anchors.fill: parent; anchors.margins: 6
                    ColumnLayout {
                        Layout.fillWidth: true
                        Label { text: model.name; font.bold: true; color: "#eef2ff" }
                        Label { text: model.summary; color: "#94a3b8"; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                    Label { text: model.owned ? qsTr("base") : (model.installed ? qsTr("installato") : ""); color: "#34d399" }
                    Button {
                        visible: !model.owned && !model.installed
                        enabled: !PolkitHelper.running
                        text: qsTr("Installa")
                        onClicked: PolkitHelper.execute("/usr/bin/rk", ["add", model.name])
                    }
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: qsTr("Il catalogo strumenti è generato dai file .desktop System/Settings presenti nel sistema; non è più hardcoded per una singola spin.")
        color: "#64748b"; font.pixelSize: 10; wrapMode: Text.Wrap
    }
}
