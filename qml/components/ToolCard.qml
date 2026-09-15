import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    property string description: ""
    property string glyph: "◆"
    property bool available: true
    signal launchRequested()

    width: 280
    height: 126
    radius: 12
    color: available ? "#131c38" : "#10172c"
    border.color: available ? "#293761" : "#1c2746"
    opacity: available ? 1.0 : 0.55

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Label { text: root.glyph; font.pixelSize: 20; color: "#a5b4fc" }
            Label {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 14
                font.bold: true
                color: "#eef2ff"
                elide: Text.ElideRight
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.description
            color: "#94a3b8"
            font.pixelSize: 11
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Button {
            Layout.alignment: Qt.AlignRight
            text: root.available ? "Apri" : "Non installato"
            enabled: root.available
            onClicked: root.launchRequested()
        }
    }
}
