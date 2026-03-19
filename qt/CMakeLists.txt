cmake_minimum_required(VERSION 3.21)
project(AgentsBoardQt VERSION 0.9.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Find Qt6
find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick Widgets)

# Path to Swift Core FFI header and library (overridable via -D)
if(NOT DEFINED CORE_FFI_INCLUDE)
    set(CORE_FFI_INCLUDE "${CMAKE_SOURCE_DIR}/../Sources/CoreFFI/include")
endif()
if(NOT DEFINED CORE_FFI_LIB_DIR)
    set(CORE_FFI_LIB_DIR "${CMAKE_SOURCE_DIR}/../.build/release")
endif()

# Declare the imported Swift Core library
add_library(agentsboard_core SHARED IMPORTED)
if(WIN32)
    set_target_properties(agentsboard_core PROPERTIES
        IMPORTED_LOCATION "${CORE_FFI_LIB_DIR}/AgentsBoardCoreFFI.dll"
        IMPORTED_IMPLIB "${CORE_FFI_LIB_DIR}/AgentsBoardCoreFFI.lib"
    )
else()
    set_target_properties(agentsboard_core PROPERTIES
        IMPORTED_LOCATION "${CORE_FFI_LIB_DIR}/libAgentsBoardCoreFFI.so"
    )
endif()
target_include_directories(agentsboard_core INTERFACE "${CORE_FFI_INCLUDE}")

# Application sources
set(SOURCES
    src/main.cpp
    src/CoreBridge.h
    src/CoreBridge.cpp
    src/FleetModel.h
    src/FleetModel.cpp
    src/SessionModel.h
    src/SessionModel.cpp
    src/ActivityModel.h
    src/ActivityModel.cpp
    src/TerminalWidget.h
    src/TerminalWidget.cpp
    src/SystemTray.h
    src/SystemTray.cpp
)

qt_add_executable(agentsboard-qt ${SOURCES})

# QML module
qt_add_qml_module(agentsboard-qt
    URI AgentsBoard
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/FleetOverview.qml
        qml/SessionCard.qml
        qml/SessionList.qml
        qml/Sidebar.qml
        qml/ActivityLog.qml
        qml/CostDashboard.qml
        qml/Terminal.qml
        qml/CommandPalette.qml
        qml/DiffReview.qml
)

target_link_libraries(agentsboard-qt PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Widgets
    agentsboard_core
)

# On Linux, CoreFFI.so depends on Swift runtime. Use swiftc as the linker
# driver so it resolves all Swift runtime symbols automatically.
if(NOT WIN32 AND NOT APPLE)
    # Disable CMake's automatic RPATH handling — swiftc doesn't understand -Wl,-rpath
    set(CMAKE_SKIP_RPATH TRUE)
    set_target_properties(agentsboard-qt PROPERTIES LINKER_LANGUAGE CXX)
    # Use swiftc as the linker — it resolves Swift runtime deps automatically.
    # -lstdc++ is needed because swiftc doesn't link C++ stdlib by default.
    set(CMAKE_CXX_LINK_EXECUTABLE
        "swiftc -Xlinker -rpath -Xlinker /usr/lib/swift/linux -Xlinker -rpath -Xlinker /usr/local/lib -Xlinker -lstdc++ <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
    )
endif()

# Install
install(TARGETS agentsboard-qt RUNTIME DESTINATION bin)
install(FILES "${CORE_FFI_LIB_DIR}/libAgentsBoardCoreFFI.so" DESTINATION lib OPTIONAL)

# Copy shared library next to executable on build
if(NOT WIN32)
    add_custom_command(TARGET agentsboard-qt POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CORE_FFI_LIB_DIR}/libAgentsBoardCoreFFI.so"
            "$<TARGET_FILE_DIR:agentsboard-qt>/"
        COMMENT "Copying libAgentsBoardCoreFFI.so to build directory"
    )
endif()
