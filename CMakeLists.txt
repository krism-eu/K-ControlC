cmake_minimum_required(VERSION 3.22)

project(KControlC
    VERSION 0.3.0
    DESCRIPTION "raku Control Center for Fedora bootc"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick DBus)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(k-controlc
    src/main.cpp
    src/BootcBackend.cpp src/BootcBackend.h
    src/SystemBackend.cpp src/SystemBackend.h
    src/PackageSearch.cpp src/PackageSearch.h
    src/PolkitHelper.cpp src/PolkitHelper.h
)

set(KCONTROLC_QML_FILES
    qml/Main.qml
    qml/components/ToolCard.qml
    qml/modules/DashboardModule.qml
    qml/modules/SoftwareModule.qml
    qml/modules/BootcModule.qml
    qml/modules/SystemModule.qml
    qml/modules/NetworkModule.qml
    qml/modules/UsersModule.qml
    qml/modules/ServicesModule.qml
    qml/modules/HardwareModule.qml
    qml/modules/StorageModule.qml
    qml/modules/FirewallModule.qml
    qml/modules/DiagnosticsModule.qml
    qml/modules/FirmwareModule.qml
    qml/modules/RecoveryModule.qml
    qml/modules/ToolsModule.qml
)

foreach(qml_file IN LISTS KCONTROLC_QML_FILES)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
endforeach()

# PackageSearch is registered at runtime. Keep the two QML files that
# instantiate it out of qmlcachegen/qmltyperegistrar, matching the CI-tested
# workaround for the previous QAbstractListModel registration failure.
set_source_files_properties(qml/modules/SoftwareModule.qml PROPERTIES QT_QML_SKIP_CACHEGEN ON)
set_source_files_properties(qml/modules/ToolsModule.qml PROPERTIES QT_QML_SKIP_CACHEGEN ON)

qt_add_qml_module(k-controlc
    URI raku.cc
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES ${KCONTROLC_QML_FILES}
)

target_link_libraries(k-controlc PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::DBus)
target_compile_definitions(k-controlc PRIVATE KCONTROLC_VERSION="${PROJECT_VERSION}")

install(TARGETS k-controlc RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES data/k-controlc.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES data/org.raku.controlcenter.policy DESTINATION ${CMAKE_INSTALL_DATADIR}/polkit-1/actions)
install(FILES data/org.raku.KControlC.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo)
install(FILES data/icons/hicolor/scalable/apps/k-controlc.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
