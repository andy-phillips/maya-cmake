set(LIB_NAME "test")

add_library(${LIB_NAME} SHARED)

target_sources(
    ${LIB_NAME}
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

if(MAYA_CMAKE_MAYA_VERSION)
    find_package(
        Maya ${MAYA_CMAKE_MAYA_VERSION} EXACT REQUIRED
        COMPONENTS
            ${MAYA_COMPONENTS_TO_FIND}
    )
else()
    find_package(
        Maya REQUIRED
        COMPONENTS
            ${MAYA_COMPONENTS_TO_FIND}
    )
endif()

target_link_libraries(
    ${LIB_NAME}
    PRIVATE
        Maya::Foundation
        Maya::Maya
)

target_compile_features(
    ${LIB_NAME}
    PRIVATE
        cxx_std_17
)

target_compile_definitions(
    ${LIB_NAME}
    PRIVATE
        "MAYA_PLUGIN_NAME=\"test\""
        "MAYA_PLUGIN_VENDOR=\"Vendor Name\""
        "MAYA_PLUGIN_VERSION=\"0.0.0\""
)

if(APPLE)
    target_compile_definitions(
        ${LIB_NAME}
        PRIVATE
            "MAC_PLUGIN"
    )

    set_target_properties(
        ${LIB_NAME}
        PROPERTIES
            OUTPUT_NAME ${LIB_NAME}
            PREFIX ""
            SUFFIX ".bundle"
    )
elseif(WIN32)
    target_compile_definitions(
        ${LIB_NAME}
        PRIVATE
            "NT_PLUGIN"
    )

    set_target_properties(
        ${LIB_NAME}
        PROPERTIES
            OUTPUT_NAME ${LIB_NAME}
            PREFIX ""
            SUFFIX ".mll"
    )
elseif(UNIX)
    set_target_properties(
        ${LIB_NAME}
        PROPERTIES
            OUTPUT_NAME ${LIB_NAME}
            PREFIX ""
            SUFFIX ".so"
    )
else()
    message(FATAL_ERROR "Unsupported OS")
endif()

install(TARGETS "${LIB_NAME}" DESTINATION "${CMAKE_INSTALL_PREFIX}/${LIB_NAME}/plug-ins")
install(FILES "test.mod" DESTINATION "${CMAKE_INSTALL_PREFIX}")

if(WIN32)
    install(
        FILES $<TARGET_PDB_FILE:${LIB_NAME}>
        DESTINATION "${CMAKE_INSTALL_PREFIX}/${LIB_NAME}/plug-ins"
        OPTIONAL
    )
endif()
