import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 16
    property string externalSearch: ""
    readonly property string effectiveQuery: externalSearch.trim().length > 0 ? externalSearch.trim().toLowerCase() : localSearch.text.trim().toLowerCase()

    Label { text: "Strumenti"; font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label {
        Layout.fillWidth: true
        text: "Utility amministrative raggruppate per categoria: il modello è simile a YaST/Mageia, mentre la selezione privilegia strumenti pratici nello spirito di MX Tools."
        color: "#94a3b8"; wrapMode: Text.Wrap
    }

    RowLayout {
        Layout.fillWidth: true
        TextField {
            id: localSearch
            Layout.fillWidth: true
            placeholderText: root.externalSearch.length > 0 ? root.externalSearch : "Filtra per nome o funzione…"
            enabled: root.externalSearch.length === 0
        }
        ComboBox {
            id: categoryFilter
            model: ["Tutti", "Sistema", "Hardware", "Software", "Rete e sicurezza", "Storage", "Diagnostica", "Virtualizzazione"]
            Layout.preferredWidth: 190
        }
    }

    Label {
        Layout.fillWidth: true
        visible: root.externalSearch.length > 0
        text: "Ricerca globale: “" + root.externalSearch + "”"
        color: "#818cf8"; font.pixelSize: 11
    }

    ListModel {
        id: toolModel
        ListElement { toolId: "systemsettings"; toolCategory: "Sistema"; toolTitle: "Impostazioni KDE"; toolDescription: "Configura desktop, schermo, input, audio, rete e preferenze Plasma."; toolGlyph: "⚙" }
        ListElement { toolId: "kinfocenter"; toolCategory: "Hardware"; toolTitle: "Centro informazioni"; toolDescription: "Hardware, grafica, memoria, dispositivi e informazioni dettagliate del sistema."; toolGlyph: "ⓘ" }
        ListElement { toolId: "partitionmanager"; toolCategory: "Storage"; toolTitle: "Partition Manager"; toolDescription: "Gestione grafica di dischi, partizioni e filesystem con i propri controlli Polkit."; toolGlyph: "▤" }
        ListElement { toolId: "firewall"; toolCategory: "Rete e sicurezza"; toolTitle: "Firewall"; toolDescription: "Interfaccia firewalld per zone, servizi, porte e regole di rete."; toolGlyph: "◉" }
        ListElement { toolId: "printer"; toolCategory: "Hardware"; toolTitle: "Stampanti"; toolDescription: "Aggiunge e configura stampanti, code CUPS e opzioni dei dispositivi."; toolGlyph: "▣" }
        ListElement { toolId: "discover"; toolCategory: "Software"; toolTitle: "Discover"; toolDescription: "Catalogo applicazioni per Flatpak e componenti desktop disponibili."; toolGlyph: "▦" }
        ListElement { toolId: "virtmanager"; toolCategory: "Virtualizzazione"; toolTitle: "Virtual Machine Manager"; toolDescription: "Gestione libvirt/KVM per macchine virtuali e reti virtualizzate."; toolGlyph: "◇" }
        ListElement { toolId: "ksystemlog"; toolCategory: "Diagnostica"; toolTitle: "KSystemLog"; toolDescription: "Consulta i log di sistema con un'interfaccia grafica dedicata."; toolGlyph: "≡" }
        ListElement { toolId: "konsole"; toolCategory: "Diagnostica"; toolTitle: "Terminale"; toolDescription: "Apre Konsole per strumenti avanzati e diagnosi manuale."; toolGlyph: ">_" }
    }

    Flow {
        id: flow
        Layout.fillWidth: true
        spacing: 12

        Repeater {
            model: toolModel
            delegate: ToolCard {
                required property string toolId
                required property string toolCategory
                required property string toolTitle
                required property string toolDescription
                required property string toolGlyph

                width: flow.width >= 900 ? (flow.width - 24) / 3 : (flow.width >= 600 ? (flow.width - 12) / 2 : flow.width)
                visible: (categoryFilter.currentText === "Tutti" || categoryFilter.currentText === toolCategory)
                         && (root.effectiveQuery.length === 0
                             || toolTitle.toLowerCase().includes(root.effectiveQuery)
                             || toolDescription.toLowerCase().includes(root.effectiveQuery)
                             || toolCategory.toLowerCase().includes(root.effectiveQuery))
                title: toolTitle
                description: toolDescription
                glyph: toolGlyph
                available: SystemBackend.toolAvailable(toolId)
                onLaunchRequested: SystemBackend.launchTool(toolId)
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 10; color: "#10172c"; border.color: "#202a4d"
        implicitHeight: hint.implicitHeight + 22
        Label {
            id: hint
            anchors.fill: parent; anchors.margins: 11
            text: "Le utility non installate restano visibili ma disabilitate: K-ControlC non installa automaticamente strumenti di amministrazione esterni."
            color: "#64748b"; font.pixelSize: 10; wrapMode: Text.Wrap
        }
    }
}
