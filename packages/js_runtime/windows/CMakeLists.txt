cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "js_runtime")
project(${PROJECT_NAME} LANGUAGES CXX)
include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} ../rust js_runtime "")
set(js_runtime_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)