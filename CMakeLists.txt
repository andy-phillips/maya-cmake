cmake_minimum_required(VERSION 3.17 FATAL_ERROR)

project(maya-cmake LANGUAGES CXX)

option(MAYA_CMAKE_BUILD_EXAMPLES "Build example plugins" OFF)

if(MAYA_CMAKE_BUILD_EXAMPLES)
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")
    add_subdirectory(test)
endif()
