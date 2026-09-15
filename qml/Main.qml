import QtQuick
import org.kde.kirigami as Kirigami
import raku.cc

Kirigami.ApplicationWindow {
    id: root
    width: 980
    height: 720
    minimumWidth: 760
    minimumHeight: 560
    visible: true
    title: qsTr("K-ControlC · raku")

    function showPage(component) {
        pageStack.replace(component)
        globalDrawer.close()
    }

    function openById(pageId) {
        if (pageId === "software") showPage(softwarePage)
        else if (pageId === "bootc") showPage(bootcPage)
        else if (pageId === "tools") showPage(toolsPage)
        else if (pageId === "recovery") showPage(recoveryPage)
        else showPage(dashboardPage)
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: globalDrawer
        title: qsTr("K-ControlC")
        titleIcon: "preferences-system"
        isMenu: true
        actions: [
            Kirigami.Action {
                text: qsTr("Panoramica")
                icon.name: "go-home"
                onTriggered: root.showPage(dashboardPage)
            },
            Kirigami.Action {
                text: qsTr("Software")
                icon.name: "system-software-install"
                onTriggered: root.showPage(softwarePage)
            },
            Kirigami.Action {
                text: qsTr("BootC")
                icon.name: "system-software-update"
                onTriggered: root.showPage(bootcPage)
            },
            Kirigami.Action {
                text: qsTr("Strumenti")
                icon.name: "applications-utilities"
                onTriggered: root.showPage(toolsPage)
            },
            Kirigami.Action {
                text: qsTr("Recovery e backup")
                icon.name: "document-save-all"
                onTriggered: root.showPage(recoveryPage)
            }
        ]
    }

    pageStack.initialPage: dashboardPage

    Component {
        id: dashboardPage
        DashboardModule {
            onOpenRequested: function(pageId) { root.openById(pageId) }
        }
    }
    Component { id: softwarePage; SoftwareModule {} }
    Component { id: bootcPage; BootcModule {} }
    Component { id: toolsPage; ToolsModule {} }
    Component { id: recoveryPage; RecoveryModule {} }
}
