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

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(k-controlc
    src/main.cpp
    src/BootcBackend.cpp
    src/BootcBackend.h
    src/SystemBackend.cpp
    src/SystemBackend.h
    src/PolkitHelper.cpp
    src/PolkitHelper.h
)

# Keep the repository organized under qml/components and qml/modules while
# exposing all application types at the raku.cc module root.
set_source_files_properties(qml/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
set_source_files_properties(qml/components/ToolCard.qml PROPERTIES QT_RESOURCE_ALIAS ToolCard.qml)
set_source_files_properties(qml/modules/DashboardModule.qml PROPERTIES QT_RESOURCE_ALIAS DashboardModule.qml)
set_source_files_properties(qml/modules/SoftwareModule.qml PROPERTIES QT_RESOURCE_ALIAS SoftwareModule.qml)
set_source_files_properties(qml/modules/BootcModule.qml PROPERTIES QT_RESOURCE_ALIAS BootcModule.qml)
set_source_files_properties(qml/modules/SystemModule.qml PROPERTIES QT_RESOURCE_ALIAS SystemModule.qml)
set_source_files_properties(qml/modules/ToolsModule.qml PROPERTIES QT_RESOURCE_ALIAS ToolsModule.qml)

qt_add_qml_module(k-controlc
    URI raku.cc
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    SOURCES
        src/PackageSearch.cpp
        src/PackageSearch.h
    QML_FILES
        qml/Main.qml
        qml/components/ToolCard.qml
        qml/modules/DashboardModule.qml
        qml/modules/SoftwareModule.qml
        qml/modules/BootcModule.qml
        qml/modules/SystemModule.qml
        qml/modules/ToolsModule.qml
)

target_link_libraries(k-controlc PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

target_compile_definitions(k-controlc PRIVATE
    KCONTROLC_VERSION="${PROJECT_VERSION}"
)

install(TARGETS k-controlc
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

install(FILES data/k-controlc.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)
install(FILES data/org.raku.controlcenter.policy
    DESTINATION ${CMAKE_INSTALL_DATADIR}/polkit-1/actions
)
