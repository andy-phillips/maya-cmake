cmake_minimum_required(VERSION 3.22.1 FATAL_ERROR)

project(maya-cmake LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")

add_subdirectory(test)
