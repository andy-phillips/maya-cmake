cmake_minimum_required(VERSION 3.17 FATAL_ERROR)

project(maya-cmake VERSION 0.0.0 LANGUAGES CXX)

option(MAYA_CMAKE_BUILD_EXAMPLES "Build example plugins" OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

if(MAYA_CMAKE_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
