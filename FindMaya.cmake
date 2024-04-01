if (NOT DEFINED ENV{MAYA_LOCATION}
    AND NOT DEFINED MAYA_LOCATION
    AND NOT DEFINED MAYA_DEVKIT_LOCATION)
    message(
        "Please set the MAYA_LOCATION variable to the Maya installation path. "
        "Alternatively set the CMake variable MAYA_DEVKIT_LOCATION to the Maya devkit path."
    )
endif()

find_path(Maya_ROOT_DIR
    "include/maya/MFn.h"
    PATHS
        "${MAYA_LOCATION}"
        "$ENV{MAYA_LOCATION}"
        "${MAYA_DEVKIT_LOCATION}"
    PATH_SUFFIXES
        "devkit"
)

find_path(Maya_LIBRARY_DIRS
    "libOpenMaya.dylib"
    "OpenMaya.lib"
    PATHS
        "${Maya_ROOT_DIR}"
    PATH_SUFFIXES
        "lib"
    NO_CACHE
)

find_path(MAYA_INCLUDE_DIR
    "maya/MFn.h"
    PATHS
        "${Maya_ROOT_DIR}"
    PATH_SUFFIXES
        "include"
    NO_CACHE
)

function(strip_version_leading_zeros VERSION_STRING VERSION_VARIABLE)
    string(REGEX REPLACE "(^0+)" "" VERSION_STRING ${VERSION_STRING})
    string(COMPARE EQUAL "${VERSION_STRING}" "" VERSION_IS_ZERO)

    if(VERSION_IS_ZERO)
        set(${VERSION_VARIABLE} "0" PARENT_SCOPE)
    else()
        set(${VERSION_VARIABLE} ${VERSION_STRING} PARENT_SCOPE)
    endif()
endfunction()

if(MAYA_INCLUDE_DIR)
    list(APPEND Maya_INCLUDE_DIRS ${MAYA_INCLUDE_DIR})

    if(EXISTS "${MAYA_INCLUDE_DIR}/maya/MTypes.h")
        file(STRINGS ${MAYA_INCLUDE_DIR}/maya/MTypes.h MAYA_VERSION_DEFINE REGEX "#define MAYA_API_VERSION.*$")
        string(REGEX MATCHALL "[0-9]+" MAYA_API_VERSION ${MAYA_VERSION_DEFINE})
    endif()

    string(SUBSTRING ${MAYA_API_VERSION} "0" "4" Maya_VERSION_MAJOR)

    string(SUBSTRING ${MAYA_API_VERSION} "4" "2" Maya_VERSION_MINOR)
    strip_version_leading_zeros(${Maya_VERSION_MINOR} Maya_VERSION_MINOR)

    string(SUBSTRING ${MAYA_API_VERSION} "6" "-1" Maya_VERSION_PATCH)
    strip_version_leading_zeros(${Maya_VERSION_PATCH} Maya_VERSION_PATCH)

    set(Maya_VERSION "${Maya_VERSION_MAJOR}.${Maya_VERSION_MINOR}.${Maya_VERSION_PATCH}")
endif()

find_program(Maya_EXECUTABLE maya
    PATHS
        "${MAYA_LOCATION}"
        "$ENV{MAYA_LOCATION}"
    PATH_SUFFIXES
        bin/
        Maya.app/Contents/bin/
    DOC "Maya's executable path"
)

set(MAYA_COMPONENTS
    Foundation:Foundation
    Maya:OpenMaya
    Anim:OpenMayaAnim
    FX:OpenMayaFX
    Render:OpenMayaRender
    UI:OpenMayaUI
    CLEW:clew
)

macro(_pair_to_key_value PAIR KEY VALUE)
    if(${PAIR} MATCHES "^([^:]+):(.*)$")
        set(${KEY} ${CMAKE_MATCH_1})
        set(${VALUE} ${CMAKE_MATCH_2})
    else()
        message(FATAL_ERROR "Invalid key / value pair: ${PAIR}")
    endif()
endmacro()

foreach(COMPONENT_PAIR ${MAYA_COMPONENTS})
    _pair_to_key_value(${COMPONENT_PAIR} _COMPONENT_NAME _LIB_NAME)

    find_library(
        MAYA_${_LIB_NAME}_LIBRARY ${_LIB_NAME}
        PATHS
            "${Maya_LIBRARY_DIRS}"
        NO_CACHE
        # NO_CMAKE_SYSTEM_PATH needed to avoid conflicts between Maya's foundation library and
        # OSX's foundation framework.
        NO_CMAKE_SYSTEM_PATH
    )

    if(MAYA_${_LIB_NAME}_LIBRARY)
        set(Maya_${_COMPONENT_NAME}_FOUND TRUE)
    endif()
endforeach()

find_library(_MAYA_TBB_LIBRARY_DEBUG tbb_debug PATHS "${Maya_LIBRARY_DIRS}" NO_CACHE)
find_library(_MAYA_TBB_LIBRARY_RELEASE tbb PATHS "${Maya_LIBRARY_DIRS}" NO_CACHE)
find_path(_MAYA_TBB_INCLUDE_DIR tbb/tbb.h PATHS "${MAYA_INCLUDE_DIR}" NO_CACHE)

if(_MAYA_TBB_LIBRARY_DEBUG
   OR _MAYA_TBB_LIBRARY_RELEASE
   AND _MAYA_TBB_INCLUDE_DIR
)
    set(_TBB_TARGET_NAME Maya::TBB)

    set(Maya_TBB_FOUND TRUE)

    if(NOT TARGET ${_TBB_TARGET_NAME})
        add_library(${_TBB_TARGET_NAME} UNKNOWN IMPORTED)
    endif()

    set_target_properties(${_TBB_TARGET_NAME}
        PROPERTIES
            IMPORTED_LOCATION "${_MAYA_TBB_LIBRARY_RELEASE}"
            INTERFACE_INCLUDE_DIRECTORIES "${_MAYA_TBB_INCLUDE_DIR}"
    )

    if(_MAYA_TBB_LIBRARY_DEBUG)
        set_property(TARGET ${_TBB_TARGET_NAME}
            APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG
        )
        set_target_properties(${_TBB_TARGET_NAME}
            PROPERTIES
                IMPORTED_LOCATION_DEBUG "${_MAYA_TBB_LIBRARY_DEBUG}")
    endif()

    unset(_TBB_TARGET_NAME)
endif()

unset(_MAYA_TBB_LIBRARY_DEBUG)
unset(_MAYA_TBB_LIBRARY_RELEASE)
unset(_MAYA_TBB_INCLUDE_DIR)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    Maya
    VERSION_VAR Maya_VERSION
    HANDLE_VERSION_RANGE
    HANDLE_COMPONENTS
)

foreach(COMPONENT_PAIR ${MAYA_COMPONENTS})
    _pair_to_key_value(${COMPONENT_PAIR} _COMPONENT_NAME _LIB_NAME)

    if(MAYA_${_LIB_NAME}_LIBRARY)
        set(TARGET_NAME Maya::${_COMPONENT_NAME})

        if(NOT TARGET ${TARGET_NAME})
            add_library(${TARGET_NAME} UNKNOWN IMPORTED)
            set_target_properties(${TARGET_NAME}
                PROPERTIES
                    IMPORTED_LOCATION "${MAYA_${_LIB_NAME}_LIBRARY}"
                    INTERFACE_INCLUDE_DIRECTORIES "${MAYA_INCLUDE_DIR}"
            )
            list(APPEND Maya_LIBRARIES ${TARGET_NAME})
        endif()
    endif()
endforeach()

mark_as_advanced(
    Maya_INCLUDE_DIRS
    Maya_LIBRARIES
)

unset(MAYA_INCLUDE_DIR)
unset(MAYA_LIBRARIES_DIR)
unset(MAYA_COMPONENTS)
unset(_COMPONENT_NAME)
