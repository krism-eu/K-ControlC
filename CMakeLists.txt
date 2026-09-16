cmake_minimum_required(VERSION 3.22)

project(KControlC
    VERSION 0.4.0
    DESCRIPTION "Personal Control Center for Fedora bootc"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick DBus)
find_package(KF6Kirigami REQUIRED)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(k-controlc
    src/main.cpp
    src/BootcBackend.cpp src/BootcBackend.h
    src/SystemBackend.cpp src/SystemBackend.h
    src/SoftwareBackend.cpp src/SoftwareBackend.h
    src/PackageSearch.cpp src/PackageSearch.h
    src/PolkitHelper.cpp src/PolkitHelper.h
    src/UtilityBackend.cpp src/UtilityBackend.h
)

set(KCONTROLC_QML_FILES
    qml/Main.qml
    qml/modules/DashboardModule.qml
    qml/modules/SoftwareModule.qml
    qml/modules/FlatpakModule.qml
    qml/modules/PodmanModule.qml
    qml/modules/BootcModule.qml
    qml/modules/ToolsModule.qml
    qml/modules/CommandsModule.qml
    qml/modules/RecoveryModule.qml
)

foreach(qml_file IN LISTS KCONTROLC_QML_FILES)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
endforeach()

# PackageSearch is registered at runtime. Keep the page that instantiates it
# out of qmlcachegen to avoid the previous QAbstractListModel registrar issue.
set_source_files_properties(qml/modules/SoftwareModule.qml PROPERTIES QT_QML_SKIP_CACHEGEN ON)

qt_add_qml_module(k-controlc
    URI org.kcontrolc
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES ${KCONTROLC_QML_FILES}
)

target_link_libraries(k-controlc PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::DBus
    KF6::Kirigami
)
target_compile_definitions(k-controlc PRIVATE KCONTROLC_VERSION="${PROJECT_VERSION}")

install(TARGETS k-controlc RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES data/k-controlc.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES data/org.kcontrolc.controlcenter.policy DESTINATION ${CMAKE_INSTALL_DATADIR}/polkit-1/actions)
install(FILES data/org.kcontrolc.KControlC.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
install(FILES data/icons/hicolor/scalable/apps/k-controlc.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
