import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 18
    signal openPage(int index)

    Label { text: qsTr("Panoramica"); font.pixelSize: 26; font.bold: true; color: "#f8fafc" }
    Label { Layout.fillWidth: true; text: qsTr("Stato rapido e azioni frequenti, con flussi coerenti con Fedora bootc."); color: "#94a3b8"; wrapMode: Text.Wrap }

    GridLayout {
        Layout.fillWidth: true; columns: width > 780 ? 4 : 2; columnSpacing: 10; rowSpacing: 10
        Repeater {
            model: [
                { title: qsTr("Sistema"), value: SystemBackend.osName, page: 3 },
                { title: qsTr("BootC"), value: BootcBackend.bootcAvailable ? qsTr("attivo") : qsTr("non disponibile"), page: 2 },
                { title: qsTr("Rete"), value: SystemBackend.networkState(), page: 4 },
                { title: qsTr("Pacchetti persistenti"), value: BootcBackend.persistentPackageCount.toString(), page: 1 }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true; Layout.preferredHeight: 118; radius: 12; color: "#131c38"; border.color: "#293761"
                ColumnLayout { anchors.fill: parent; anchors.margins: 14
                    Label { text: modelData.title; color: "#818cf8"; font.bold: true }
                    Label { Layout.fillWidth: true; text: modelData.value; color: "#f8fafc"; wrapMode: Text.Wrap; elide: Text.ElideRight }
                    Item { Layout.fillHeight: true }
                    Button { text: qsTr("Apri"); onClicked: root.openPage(modelData.page) }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true; Layout.preferredHeight: 245; radius: 12; color: "#111831"; border.color: "#253158"
        ColumnLayout { anchors.fill: parent; anchors.margins: 16; spacing: 8
            Label { text: qsTr("Quick System Info"); font.bold: true; font.pixelSize: 15; color: "#e0e7ff" }
            TextArea { id: quickInfo; Layout.fillWidth: true; Layout.fillHeight: true; readOnly: true; text: SystemBackend.quickSystemInfo(); font.family: "monospace"; font.pixelSize: 11; color: "#cbd5e1"; background: Rectangle { color: "#0b1124"; radius: 8 } }
            RowLayout {
                Button { text: qsTr("Copia negli appunti"); onClicked: SystemBackend.copyToClipboard(quickInfo.text) }
                Button { text: qsTr("Diagnostica"); onClicked: root.openPage(10) }
                Button { text: qsTr("Tutti gli strumenti"); onClicked: root.openPage(13) }
            }
        }
    }
}
