# MIT License
#
# Copyright (c) 2024 Andrew Phillips
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#[=============================================================================[.rst:

FindMaya
--------

Finds the Maya SDK (devkit) libraries and Maya specific versions of 3rd pary libraries.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported targets, if found:

``Maya::Foundation``
    The foundation library

``Maya::Maya``
    The OpenMaya library

``Maya::Anim``
    The OpenMayaAnim library

``Maya::FX``
    The OpenMayaFX library

``Maya::Render``
    The OpenMayaRender library

``Maya::UI``
    The OpenMayaUI library

Result Variables
^^^^^^^^^^^^^^^^

``Maya_FOUND``
    True if the system has the Maya SDK libraries.

``Maya_VERSION_MAJOR``
  The major version of the Maya API.

``Maya_VERSION_MINOR``
  The minor version of the Maya API.

``Maya_VERSION``
  Full version in the ``X.Y`` format.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``Maya_SDK_ROOT_DIR``
    Path to the Maya SDK (defined if not set).

``Maya_EXECUTABLE``
    Path to the Maya executable (defined if not set).

#]=============================================================================]

find_path(Maya_SDK_ROOT_DIR
    "include/maya/MFn.h"
    PATHS
        "${DEVKIT_LOCATION}"
        "$ENV{DEVKIT_LOCATION}"
        "$ENV{HOME}"
        "$ENV{USERPROFILE}"
    PATH_SUFFIXES
        "devkit"
        "devkitBase"
    DOC
        "Absolute path to the Maya SDK (devkit) directory."
)

if(NOT Maya_SDK_ROOT_DIR)
    set(Maya_FAILURE_MESSAGE
        "Maya SDK could not be found. Check that is installed on the system, "
    )
    string(CONCAT Maya_FAILURE_MESSAGE ${Maya_FAILURE_MESSAGE} 
        "and the DEVKIT_LOCATION environment variable is set."
    )
endif()

if(Maya_SDK_ROOT_DIR AND NOT EXISTS "${Maya_SDK_ROOT_DIR}")
    set(Maya_FAILURE_MESSAGE "Maya_SDK_ROOT_DIR variable is set but the path does not exist: ")
    string(CONCAT Maya_FAILURE_MESSAGE ${Maya_FAILURE_MESSAGE} "${Maya_SDK_ROOT_DIR}")
endif()

find_path(Maya_INCLUDE_DIR
    "maya/MFn.h"
    PATHS
        "${Maya_SDK_ROOT_DIR}"
    PATH_SUFFIXES
        "include"
    NO_CACHE
)

find_path(Maya_LIBRARY_DIR
    "OpenMaya.lib"
    "libOpenMaya.so"
    "libOpenMaya.dylib"
    PATHS
        "${Maya_SDK_ROOT_DIR}"
    PATH_SUFFIXES
        "lib"
    NO_CACHE
)

if(Maya_SDK_ROOT_DIR)
    unset(Maya_FAILURE_MESSAGE)

    if (NOT Maya_INCLUDE_DIR AND NOT Maya_LIBRARY_DIR)
        set(Maya_FAILURE_MESSAGE "Missing include and lib directory in directory: ")
    elseif (NOT Maya_INCLUDE_DIR)
        set(Maya_FAILURE_MESSAGE "Missing include directory in directory: ")
    elseif (NOT Maya_LIBRARY_DIR)
        set(Maya_FAILURE_MESSAGE "Missing lib directory in directory: ")
    endif()

    if(Maya_FAILURE_MESSAGE)
        string(CONCAT Maya_FAILURE_MESSAGE ${Maya_FAILURE_MESSAGE} "${Maya_SDK_ROOT_DIR}")
    endif()
endif()

function(maya_extract_version_from_file FILE_PATH)
    file(STRINGS "${FILE_PATH}" VERSION_DEFINE REGEX "#define MAYA_API_VERSION.*$")
    string(REGEX MATCHALL "[0-9]+" API_VERSION "${VERSION_DEFINE}")

    string(SUBSTRING "${API_VERSION}" "0" "4" Maya_VERSION_MAJOR)
    set(Maya_VERSION_MAJOR "${Maya_VERSION_MAJOR}" PARENT_SCOPE)

    string(SUBSTRING ${API_VERSION} "4" "2" Maya_VERSION_MINOR)
    string(REGEX REPLACE "(^0+)" "" Maya_VERSION_MINOR "${Maya_VERSION_MINOR}")
    string(COMPARE EQUAL "${Maya_VERSION_MINOR}" "" VERSION_IS_ZERO)

    if(VERSION_IS_ZERO)
        set(Maya_VERSION_MINOR "0")
    else()
        set(Maya_VERSION_MINOR "${Maya_VERSION_MINOR}")
    endif()
    set(Maya_VERSION_MINOR "${Maya_VERSION_MINOR}" PARENT_SCOPE)

    set(Maya_VERSION "${Maya_VERSION_MAJOR}.${Maya_VERSION_MINOR}" PARENT_SCOPE)
endfunction()

if(Maya_INCLUDE_DIR AND EXISTS "${Maya_INCLUDE_DIR}/maya/MTypes.h")
    maya_extract_version_from_file("${Maya_INCLUDE_DIR}/maya/MTypes.h")
endif()

set(Maya_COMPONENTS
    Foundation:Foundation
    Maya:OpenMaya
    Anim:OpenMayaAnim
    FX:OpenMayaFX
    Render:OpenMayaRender
    UI:OpenMayaUI
    CLEW:clew
)

macro(maya_pair_to_key_value PAIR KEY VALUE)
    if(${PAIR} MATCHES "^([^:]+):(.*)$")
        set(${KEY} ${CMAKE_MATCH_1})
        set(${VALUE} ${CMAKE_MATCH_2})
    else()
        message(FATAL_ERROR "Invalid key / value pair: ${PAIR}")
    endif()
endmacro()

foreach(COMPONENT_PAIR ${Maya_COMPONENTS})
    maya_pair_to_key_value(${COMPONENT_PAIR} Maya_COMPONENT_NAME Maya_LIB_NAME)

    find_library(
        Maya_${Maya_LIB_NAME}_LIBRARY
        ${Maya_LIB_NAME}
        PATHS
            "${Maya_LIBRARY_DIR}"
        NO_CACHE
        # NO_CMAKE_SYSTEM_PATH needed to avoid conflicts between Maya's foundation library and
        # OSX's foundation framework.
        NO_CMAKE_SYSTEM_PATH
    )

    if(Maya_${Maya_LIB_NAME}_LIBRARY)
        set(Maya_${Maya_COMPONENT_NAME}_FOUND TRUE)
    endif()
endforeach()

find_path(Maya_TBB_INCLUDE_DIR "tbb/tbb.h" PATHS "${Maya_INCLUDE_DIR}" NO_CACHE)
find_library(Maya_TBB_LIBRARY_DEBUG "tbb_debug" PATHS "${Maya_LIBRARY_DIR}" NO_CACHE)
find_library(Maya_TBB_LIBRARY_RELEASE "tbb" PATHS "${Maya_LIBRARY_DIR}" NO_CACHE)

if(Maya_TBB_LIBRARY_RELEASE AND Maya_TBB_INCLUDE_DIR)
    set(Maya_TBB_FOUND TRUE)
endif()

function(maya_find_executable)
    if(APPLE)
        set(DEFAULT_INSTALL_DIR "/Applications/Autodesk")
    elseif(UNIX)
        set(DEFAULT_INSTALL_DIR "/usr/autodesk")
    elseif(WIN32)
        set(DEFAULT_INSTALL_DIR "C:\\Program Files\\Autodesk")
    endif()

    find_program(Maya_EXECUTABLE
        "maya"
        PATHS
            "${MAYA_LOCATION}"
            "$ENV{MAYA_LOCATION}"
            "${DEFAULT_INSTALL_DIR}"
        PATH_SUFFIXES
            "bin"
            "maya${Maya_VERSION_MAJOR}/Maya.app/Contents/bin"
        DOC
            "Absolute path to Maya executable."
    )

    set(Maya_EXECUTABLE "${Maya_EXECUTABLE}" PARENT_SCOPE)
endfunction()

maya_find_executable()

include(FindPackageHandleStandardArgs)

# NOTE: If the package was found, it will print the contents of the first
# required variable to indicate where it was found.
find_package_handle_standard_args(
    Maya
    VERSION_VAR Maya_VERSION
    REQUIRED_VARS
        Maya_SDK_ROOT_DIR
        Maya_INCLUDE_DIR
        Maya_LIBRARY_DIR
    HANDLE_VERSION_RANGE
    HANDLE_COMPONENTS
    REASON_FAILURE_MESSAGE "${Maya_FAILURE_MESSAGE}"
)
unset(Maya_FAILURE_MESSAGE)

mark_as_advanced(
    Maya_SDK_ROOT_DIR
    Maya_EXECUTABLE
)

function(maya_add_import_target TARGET_SUFFIX)
    cmake_parse_arguments(
        TARGET
        ""
        "INCLUDE_DIR;LIBRARY_DEBUG;LIBRARY_RELEASE"
        ""
        ${ARGN}
    )

    set(TARGET_NAME "Maya::${TARGET_SUFFIX}")

    if(NOT TARGET ${TARGET_NAME})
        add_library(${TARGET_NAME} UNKNOWN IMPORTED)
    endif()

    set_target_properties(${TARGET_NAME}
        PROPERTIES
            IMPORTED_LOCATION "${TARGET_LIBRARY_RELEASE}"
            INTERFACE_INCLUDE_DIRECTORIES "${TARGET_INCLUDE_DIR}"
    )

    if(TARGET_LIBRARY_DEBUG)
        set_property(TARGET ${TARGET_NAME}
            APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG
        )
        set_target_properties(${TARGET_NAME}
            PROPERTIES
                IMPORTED_LOCATION_DEBUG "${TARGET_LIBRARY_DEBUG}")
    endif()
endfunction()

foreach(COMPONENT_PAIR ${Maya_COMPONENTS})
    maya_pair_to_key_value(${COMPONENT_PAIR} Maya_COMPONENT_NAME Maya_LIB_NAME)

    if(Maya_${Maya_COMPONENT_NAME}_FOUND)
        maya_add_import_target(${Maya_COMPONENT_NAME}
            INCLUDE_DIR "${Maya_INCLUDE_DIR}"
            LIBRARY_RELEASE "${Maya_${Maya_LIB_NAME}_LIBRARY}"
        )
    endif()
endforeach()

unset(Maya_COMPONENT_NAME)
unset(Maya_LIB_NAME)
unset(Maya_COMPONENTS)

if(Maya_TBB_FOUND)
    maya_add_import_target(TBB
        INCLUDE_DIR ${Maya_TBB_INCLUDE_DIR}
        LIBRARY_DEBUG ${Maya_TBB_LIBRARY_DEBUG}
        LIBRARY_RELEASE ${Maya_TBB_LIBRARY_RELEASE}
    )
endif()

unset(Maya_INCLUDE_DIR)
unset(Maya_LIBRARY_DIR)
