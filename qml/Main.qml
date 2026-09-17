import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kriscc

Kirigami.ApplicationWindow {
    id: root
    width: 1120
    height: 780
    minimumWidth: 820
    minimumHeight: 600
    visible: !KrisccStartHidden
    title: qsTr("krisCC")

    function showIndex(index) {
        topTabs.currentIndex = index
        if (index === 1) pageStack.replace(softwarePage)
        else if (index === 2) pageStack.replace(flatpakPage)
        else if (index === 3) pageStack.replace(podmanPage)
        else if (index === 4) pageStack.replace(systemPage)
        else if (index === 5) pageStack.replace(commandsPage)
        else if (index === 6) pageStack.replace(recoveryPage)
        else pageStack.replace(dashboardPage)
    }

    function openById(pageId) {
        if (pageId === "software") showIndex(1)
        else if (pageId === "flatpak") showIndex(2)
        else if (pageId === "podman") showIndex(3)
        else if (pageId === "system" || pageId === "bootc" || pageId === "tools") showIndex(4)
        else if (pageId === "commands") showIndex(5)
        else if (pageId === "recovery") showIndex(6)
        else showIndex(0)
    }

    header: Controls.ToolBar {
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing

                Controls.Label {
                    Layout.fillWidth: true
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                    text: qsTr("krisCC")
                }
                Controls.Label {
                    opacity: 0.58
                    text: qsTr("KrisOS · %1").arg(Qt.application.version)
                }
            }

            Controls.TabBar {
                id: topTabs
                Layout.fillWidth: true
                onCurrentIndexChanged: {
                    if (pageStack.depth > 0) {
                        var i = currentIndex
                        if (i === 1) pageStack.replace(softwarePage)
                        else if (i === 2) pageStack.replace(flatpakPage)
                        else if (i === 3) pageStack.replace(podmanPage)
                        else if (i === 4) pageStack.replace(systemPage)
                        else if (i === 5) pageStack.replace(commandsPage)
                        else if (i === 6) pageStack.replace(recoveryPage)
                        else pageStack.replace(dashboardPage)
                    }
                }

                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("Panoramica") }
                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("RPM") }
                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("Flatpak") }
                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("Container") }
                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("Sistema") }
                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("Comandi") }
                Controls.TabButton { width: topTabs.width / 7; implicitHeight: Kirigami.Units.gridUnit * 2.15; font.bold: checked; text: qsTr("Backup") }
            }
        }
    }

    pageStack.initialPage: dashboardPage

    Component {
        id: dashboardPage
        DashboardModule {
            onOpenRequested: function(pageId) { root.openById(pageId) }
        }
    }
    Component { id: softwarePage; SoftwareModule {} }
    Component { id: flatpakPage; FlatpakModule {} }
    Component { id: podmanPage; PodmanModule {} }
    Component { id: systemPage; SystemModule {} }
    Component { id: commandsPage; CommandsModule {} }
    Component { id: recoveryPage; RecoveryModule {} }
}
