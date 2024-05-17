set(PLUGIN_NAME "examples")

add_library(${PLUGIN_NAME} SHARED)

target_sources(
    ${PLUGIN_NAME}
    PRIVATE
        plugin.cpp
)

set(MAYA_COMPONENTS_TO_FIND
    Foundation
    Maya
    Anim
    FX
    Render
    UI
)

set(MAYA_OPTIONAL_COMPONENTS_TO_FIND
    TBB
    CLEW
)

if(MAYA_CMAKE_MAYA_VERSION)
    find_package(
        Maya ${MAYA_CMAKE_MAYA_VERSION} EXACT REQUIRED
        COMPONENTS
            ${MAYA_COMPONENTS_TO_FIND}
        OPTIONAL_COMPONENTS
            ${MAYA_OPTIONAL_COMPONENTS_TO_FIND}
    )
else()
    find_package(
        Maya REQUIRED
        COMPONENTS
            ${MAYA_COMPONENTS_TO_FIND}
        OPTIONAL_COMPONENTS
            ${MAYA_OPTIONAL_COMPONENTS_TO_FIND}
    )
endif()

target_link_libraries(
    ${PLUGIN_NAME}
    PRIVATE
        Maya::Foundation
        Maya::Maya
)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(PLATFORM_TARGET_DEFINITIONS "NT_PLUGIN")
    set(PLATFORM_TARGET_SUFFIX ".mll") 
    set(PLATFORM_MAYA_MODULE_PLATFORM "win64")
elseif(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(PLATFORM_TARGET_DEFINITIONS "MAC_PLUGIN")
    set(PLATFORM_TARGET_SUFFIX ".bundle") 
    set(PLATFORM_MAYA_MODULE_PLATFORM "mac")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(PLATFORM_TARGET_SUFFIX ".so") 
    set(PLATFORM_MAYA_MODULE_PLATFORM "linux")
else()
    message(FATAL_ERROR "Unsupported operating system")
endif()

set_target_properties(
    ${PLUGIN_NAME}
    PROPERTIES
        OUTPUT_NAME ${PLUGIN_NAME}
        PREFIX ""
        SUFFIX "${PLATFORM_TARGET_SUFFIX}"
)

target_compile_definitions(
    ${PLUGIN_NAME}
    PRIVATE
        "MAYA_PLUGIN_NAME=\"${PLUGIN_NAME}\""
        "MAYA_PLUGIN_VENDOR=\"Vendor Name\""
        "MAYA_PLUGIN_VERSION=\"${PROJECT_VERSION}\""
        "${PLATFORM_TARGET_DEFINITIONS}"
)

configure_file("${PROJECT_NAME}.mod.in" "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.mod")
install(FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.mod" DESTINATION "${CMAKE_INSTALL_PREFIX}")

install(TARGETS "${PLUGIN_NAME}" DESTINATION "${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}/${PLUGIN_NAME}/plug-ins")

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    install(
        FILES $<TARGET_PDB_FILE:${PLUGIN_NAME}>
        DESTINATION "${CMAKE_INSTALL_PREFIX}/${PROJECT}/${PLUGIN_NAME}/plug-ins"
        OPTIONAL
    )
endif()
