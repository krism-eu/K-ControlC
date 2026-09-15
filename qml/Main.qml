import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import raku.cc

ApplicationWindow {
    id: window
    width: 1220
    height: 800
    minimumWidth: 920
    minimumHeight: 640
    visible: true
    title: qsTr("K-ControlC · raku Control Center")
    color: "#0b1020"

    property int pageIndex: 0
    property var navigation: [
        { label: qsTr("Panoramica"), glyph: "⌂" },
        { label: qsTr("Software"), glyph: "▦" },
        { label: qsTr("Deployment"), glyph: "↻" },
        { label: qsTr("Sistema"), glyph: "⚙" },
        { label: qsTr("Rete"), glyph: "◎" },
        { label: qsTr("Utenti"), glyph: "♙" },
        { label: qsTr("Servizi"), glyph: "◫" },
        { label: qsTr("Hardware"), glyph: "◇" },
        { label: qsTr("Storage"), glyph: "▤" },
        { label: qsTr("Firewall"), glyph: "◉" },
        { label: qsTr("Diagnostica"), glyph: "≡" },
        { label: qsTr("Firmware"), glyph: "⬡" },
        { label: qsTr("Recovery"), glyph: "↶" },
        { label: qsTr("Strumenti"), glyph: "◆" }
    ]

    palette.window: "#0b1020"
    palette.windowText: "#e5e7eb"
    palette.base: "#111831"
    palette.alternateBase: "#171f3d"
    palette.text: "#e5e7eb"
    palette.button: "#1b2548"
    palette.buttonText: "#e5e7eb"
    palette.highlight: "#6366f1"
    palette.highlightedText: "#ffffff"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 270
            Layout.fillHeight: true
            color: "#0f1630"
            border.color: "#202a4d"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Label { text: "K-ControlC"; font.pixelSize: 24; font.bold: true; color: "#f8fafc" }
                    Label { text: "raku · Fedora bootc"; font.pixelSize: 11; color: "#818cf8" }
                }

                TextField {
                    id: globalSearch
                    Layout.fillWidth: true
                    placeholderText: qsTr("Cerca moduli, strumenti, pacchetti…")
                    selectByMouse: true
                    onTextChanged: if (text.trim().length > 0) window.pageIndex = 13
                }

                ListView {
                    id: navList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 3
                    model: window.navigation
                    delegate: Button {
                        required property int index
                        required property var modelData
                        width: navList.width
                        height: 38
                        checkable: true
                        checked: window.pageIndex === index
                        text: modelData.glyph + "   " + modelData.label
                        onClicked: {
                            window.pageIndex = index
                            if (index !== 13) globalSearch.clear()
                        }
                        contentItem: Label {
                            text: parent.text
                            color: parent.checked ? "#ffffff" : "#cbd5e1"
                            font.pixelSize: 12
                            font.bold: parent.checked
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            radius: 8
                            color: parent.checked ? "#4f46e5" : (parent.hovered ? "#192449" : "transparent")
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 9
                    color: "#111b38"
                    border.color: "#26335d"
                    implicitHeight: statusCol.implicitHeight + 18
                    ColumnLayout {
                        id: statusCol
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 2
                        Label { text: qsTr("Stato sistema"); font.bold: true; color: "#c7d2fe" }
                        Label {
                            text: BootcBackend.bootcAvailable ? qsTr("● bootc rilevato") : qsTr("○ bootc non rilevato")
                            color: BootcBackend.bootcAvailable ? "#34d399" : "#94a3b8"
                            font.pixelSize: 10
                        }
                        Label { text: qsTr("%1 pacchetti persistenti").arg(BootcBackend.persistentPackageCount); color: "#94a3b8"; font.pixelSize: 10 }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0b1020"

            StackLayout {
                anchors.fill: parent
                currentIndex: window.pageIndex

                Item { ScrollView { id: p0; anchors.fill: parent; padding: 26; contentWidth: availableWidth; DashboardModule { width: p0.availableWidth - 52; onOpenPage: function(i) { window.pageIndex = i } } } }
                Item { ScrollView { id: p1; anchors.fill: parent; padding: 26; contentWidth: availableWidth; SoftwareModule { width: p1.availableWidth - 52 } } }
                Item { ScrollView { id: p2; anchors.fill: parent; padding: 26; contentWidth: availableWidth; BootcModule { width: p2.availableWidth - 52 } } }
                Item { ScrollView { id: p3; anchors.fill: parent; padding: 26; contentWidth: availableWidth; SystemModule { width: p3.availableWidth - 52 } } }
                Item { ScrollView { id: p4; anchors.fill: parent; padding: 26; contentWidth: availableWidth; NetworkModule { width: p4.availableWidth - 52 } } }
                Item { ScrollView { id: p5; anchors.fill: parent; padding: 26; contentWidth: availableWidth; UsersModule { width: p5.availableWidth - 52 } } }
                Item { ScrollView { id: p6; anchors.fill: parent; padding: 26; contentWidth: availableWidth; ServicesModule { width: p6.availableWidth - 52 } } }
                Item { ScrollView { id: p7; anchors.fill: parent; padding: 26; contentWidth: availableWidth; HardwareModule { width: p7.availableWidth - 52 } } }
                Item { ScrollView { id: p8; anchors.fill: parent; padding: 26; contentWidth: availableWidth; StorageModule { width: p8.availableWidth - 52 } } }
                Item { ScrollView { id: p9; anchors.fill: parent; padding: 26; contentWidth: availableWidth; FirewallModule { width: p9.availableWidth - 52 } } }
                Item { ScrollView { id: p10; anchors.fill: parent; padding: 26; contentWidth: availableWidth; DiagnosticsModule { width: p10.availableWidth - 52 } } }
                Item { ScrollView { id: p11; anchors.fill: parent; padding: 26; contentWidth: availableWidth; FirmwareModule { width: p11.availableWidth - 52 } } }
                Item { ScrollView { id: p12; anchors.fill: parent; padding: 26; contentWidth: availableWidth; RecoveryModule { width: p12.availableWidth - 52 } } }
                Item {
                    ScrollView {
                        id: p13
                        anchors.fill: parent
                        padding: 26
                        contentWidth: availableWidth
                        ToolsModule {
                            width: p13.availableWidth - 52
                            externalSearch: globalSearch.text
                            onOpenPage: function(i) { window.pageIndex = i; globalSearch.clear() }
                        }
                    }
                }
            }
        }
    }
}
