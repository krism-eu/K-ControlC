import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kcontrolc

Kirigami.ApplicationWindow {
    id: root
    width: 1080
    height: 760
    minimumWidth: 800
    minimumHeight: 580
    visible: !KccStartHidden
    title: qsTr("KCC")

    function showIndex(index) {
        topTabs.currentIndex = index
        if (index === 1) pageStack.replace(softwarePage)
        else if (index === 2) pageStack.replace(flatpakPage)
        else if (index === 3) pageStack.replace(podmanPage)
        else if (index === 4) pageStack.replace(bootcPage)
        else if (index === 5) pageStack.replace(toolsPage)
        else if (index === 6) pageStack.replace(commandsPage)
        else if (index === 7) pageStack.replace(recoveryPage)
        else pageStack.replace(dashboardPage)
    }

    function openById(pageId) {
        if (pageId === "software") showIndex(1)
        else if (pageId === "flatpak") showIndex(2)
        else if (pageId === "podman") showIndex(3)
        else if (pageId === "bootc") showIndex(4)
        else if (pageId === "tools") showIndex(5)
        else if (pageId === "recovery") showIndex(7)
        else showIndex(0)
    }

    header: Controls.ToolBar {
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            RowLayout {
                Layout.fillWidth: true
                Controls.Label {
                    Layout.fillWidth: true
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
                    text: qsTr("KCC")
                }
                Controls.Label {
                    opacity: 0.62
                    text: qsTr("versione %1").arg(Qt.application.version)
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
                        else if (i === 4) pageStack.replace(bootcPage)
                        else if (i === 5) pageStack.replace(toolsPage)
                        else if (i === 6) pageStack.replace(commandsPage)
                        else if (i === 7) pageStack.replace(recoveryPage)
                        else pageStack.replace(dashboardPage)
                    }
                }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("Panoramica") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("RPM") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("Flatpak") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("Container") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("BootC") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("Strumenti") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("Comandi") }
                Controls.TabButton { width: topTabs.width / 8; text: qsTr("Backup") }
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
    Component { id: bootcPage; BootcModule {} }
    Component { id: toolsPage; ToolsModule {} }
    Component { id: commandsPage; CommandsModule {} }
    Component { id: recoveryPage; RecoveryModule {} }
}
