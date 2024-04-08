# maya-cmake
A modern [CMake](https://cmake.org) module for the Autodesk® Maya® SDK (also known as the Maya "devkit").

## Motivation
*Why yet another CMake module?*

Whilst the Maya SDK includes a CMake module, it does not provide imported targets (also known as package components), but instead only sets a few variables such as the library and include directories.

Imported targets are a more concise way to link libraries, handle includes, and target properties.

## Installation

### Prerequisites

Download and extract the Maya SDK from the [Autodesk Platform Services](https://aps.autodesk.com/developer/overview/maya) website.

Create the environment variable `DEVKIT_LOCATION` and set it to the `devkitBase` subdirectory.

### Manual Install

Download or clone this repository and copy the *cmake* directory into the top level directory of your CMake project.

### Install Using FetchContent

Alternatively the module can be fetched on demand using CMake.

```CMake
include(FetchContent)

# Checks if the Maya package can be found locally, before attempting to retrieve
# it from the git repository.
# NOTE: Replace the GIT_TAG branch name with a full commit hash to a release version tag.
FetchContent_Declare(MAYA_CMAKE
                     GIT_REPOSITORY https://github.com/andy-phillips/maya-cmake.git
                     GIT_TAG origin/dev
                     FIND_PACKAGE_ARGS
                        NAMES Maya
)
FetchContent_GetProperties(MAYA_CMAKE)
if(NOT MAYA_CMAKE_POPULATED)
    FetchContent_Populate(MAYA_CMAKE)
endif()

# Append the module path from the dependencies source directory.
list(APPEND CMAKE_MODULE_PATH "${MAYA_CMAKE_SOURCE_DIR}/cmake/modules")
```

## Usage

Add the *modules* sub-directory to the **CMAKE_MODULE_PATH** in your project's CMakeLists file.

```CMake
# Add this before calling find_package.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
```

Use the [find_package()](https://cmake.org/cmake/help/latest/command/find_package.html#command:find_package) command to find the Maya components. If no components are specified, targets for all known components will be available (if found). 

```CMake
find_package(
    Maya 2024 REQUIRED
    COMPONENTS
        Foundation Maya Anim FX Render UI
    OPTIONAL_COMPONENTS
        TBB
    )

target_link_libraries(
    ${PLUGIN_NAME}
    PRIVATE
        Maya::Foundation
        Maya::Maya
)
```

### Imported Targets

The Maya CMake module provides the following imported targets, if found:

`Maya::Foundation` - The foundation library.

`Maya::Maya` - The OpenMaya library.

`Maya::Anim` - The OpenMayaAnim library.

`Maya::FX` - The OpenMayaFX library.

`Maya::Render` - The OpenMayaRender library.

`Maya::UI` - The OpenMayaUI library.

`Maya::TBB` - The Maya compatible version of the TBB library.

`Maya::CLEW` - The Maya compatible version of the CLEW library.

### Result Variables

`Maya_FOUND` - True if the system has the Maya SDK libraries.

`Maya_VERSION_MAJOR` - The major version of the Maya API.

`Maya_VERSION_MINOR` - The minor version of the Maya API.

`Maya_VERSION` - Full version in the `X.Y` format.

`Maya_Xxx_FOUND` - True if the component Xxx is found.

### Cache Variables

The following cache variables may also be set:

`Maya_SDK_ROOT_DIR` - Path to the Maya SDK if found (defined if not set).

`Maya_EXECUTABLE` - Path to the Maya executable if found (defined if not set).
