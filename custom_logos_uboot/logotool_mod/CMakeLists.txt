cmake_minimum_required(VERSION 3.21)
project(logotool C)

set(CMAKE_C_STANDARD 23)

add_executable(logotool logotool.c)
target_link_libraries(logotool png)
