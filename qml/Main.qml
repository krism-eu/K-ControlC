import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import raku.cc

ApplicationWindow {
    id: window
    width: 1180
    height: 760
    minimumWidth: 900
    minimumHeight: 620
    visible: true
    title: "K-ControlC · raku Control Center"
    color: "#0b1020"

    property int pageIndex: 0

    palette.window: "#0b1020"
    palette.windowText: "#e5e7eb"
    palette.base: "#111831"
    palette.alternateBase: "#171f3d"
    palette.text: "#e5e7eb"
    palette.button: "#1b2548"
    palette.buttonText: "#e5e7eb"
    palette.highlight: "#6366f1"
    palette.highlightedText: "#ffffff"

    ListModel {
        id: navigation
        ListElement { label: "Panoramica"; glyph: "⌂" }
        ListElement { label: "Software"; glyph: "▦" }
        ListElement { label: "Aggiornamenti"; glyph: "↻" }
        ListElement { label: "Sistema"; glyph: "⚙" }
        ListElement { label: "Strumenti"; glyph: "◆" }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 262
            Layout.fillHeight: true
            color: "#0f1630"
            border.color: "#202a4d"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "K-ControlC"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#f8fafc"
                    }
                    Label {
                        text: "raku · Fedora bootc"
                        font.pixelSize: 11
                        color: "#818cf8"
                    }
                }

                TextField {
                    id: globalSearch
                    Layout.fillWidth: true
                    placeholderText: "Cerca strumenti…"
                    selectByMouse: true
                    onTextChanged: {
                        if (text.trim().length > 0)
                            window.pageIndex = 4
                    }
                }

                Repeater {
                    model: navigation
                    delegate: Button {
                        required property int index
                        required property string label
                        required property string glyph
                        Layout.fillWidth: true
                        checkable: true
                        checked: window.pageIndex === index
                        text: glyph + "   " + label
                        onClicked: {
                            window.pageIndex = index
                            if (index !== 4)
                                globalSearch.clear()
                        }
                        contentItem: Label {
                            text: parent.text
                            color: parent.checked ? "#ffffff" : "#cbd5e1"
                            font.pixelSize: 13
                            font.bold: parent.checked
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        background: Rectangle {
                            radius: 9
                            color: parent.checked ? "#4f46e5" : (parent.hovered ? "#192449" : "transparent")
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 10
                    color: "#111b38"
                    border.color: "#26335d"
                    implicitHeight: statusCol.implicitHeight + 22
                    ColumnLayout {
                        id: statusCol
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 3
                        Label { text: "Stato sistema"; font.bold: true; color: "#c7d2fe" }
                        Label {
                            text: BootcBackend.bootcAvailable ? "● bootc rilevato" : "○ bootc non rilevato"
                            color: BootcBackend.bootcAvailable ? "#34d399" : "#94a3b8"
                            font.pixelSize: 11
                        }
                        Label {
                            text: BootcBackend.persistentPackageCount + " pacchetti persistenti"
                            color: "#94a3b8"; font.pixelSize: 11
                        }
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

                Item {
                    ScrollView {
                        id: dashScroll
                        anchors.fill: parent
                        padding: 28
                        contentWidth: availableWidth
                        DashboardModule {
                            width: dashScroll.availableWidth - 56
                            onOpenPage: function(index) { window.pageIndex = index }
                        }
                    }
                }
                Item {
                    ScrollView {
                        id: softwareScroll
                        anchors.fill: parent
                        padding: 28
                        contentWidth: availableWidth
                        SoftwareModule { width: softwareScroll.availableWidth - 56 }
                    }
                }
                Item {
                    ScrollView {
                        id: bootcScroll
                        anchors.fill: parent
                        padding: 28
                        contentWidth: availableWidth
                        BootcModule { width: bootcScroll.availableWidth - 56 }
                    }
                }
                Item {
                    ScrollView {
                        id: systemScroll
                        anchors.fill: parent
                        padding: 28
                        contentWidth: availableWidth
                        SystemModule { width: systemScroll.availableWidth - 56 }
                    }
                }
                Item {
                    ScrollView {
                        id: toolsScroll
                        anchors.fill: parent
                        padding: 28
                        contentWidth: availableWidth
                        ToolsModule {
                            width: toolsScroll.availableWidth - 56
                            externalSearch: globalSearch.text
                        }
                    }
                }
            }
        }
    }
}
