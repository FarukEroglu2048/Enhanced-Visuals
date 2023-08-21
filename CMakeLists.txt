cmake_minimum_required(VERSION 3.20)

project("Enhanced Visuals")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_library(enhanced_visuals SHARED "src/enhanced_visuals.cpp")

set(XPLM_API_INCLUDE_DIRECTORY "" CACHE PATH "XPLM API include directory")

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(XPLM_API_LIBRARY_FILE "" CACHE PATH "XPLM API library file")
    target_link_libraries(enhanced_visuals PRIVATE ${XPLM_API_LIBRARY_FILE})
endif()

find_package(OpenGL REQUIRED)

find_package(glbinding REQUIRED)
find_package(globjects REQUIRED)

find_package(glm REQUIRED)

target_include_directories(enhanced_visuals PRIVATE ${XPLM_API_INCLUDE_DIRECTORY} glm::glm)
target_compile_definitions(enhanced_visuals PRIVATE "XPLM400=1" "XPLM303=1" "XPLM301=1" "XPLM300=1" "XPLM210=1" "XPLM200=1")
target_link_libraries(enhanced_visuals PRIVATE OpenGL::GL glbinding::glbinding globjects::globjects)

set_target_properties(enhanced_visuals PROPERTIES PREFIX "")
set_target_properties(enhanced_visuals PROPERTIES SUFFIX ".xpl")

install(DIRECTORY "Enhanced Visuals" DESTINATION ${CMAKE_INSTALL_PREFIX})

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_compile_definitions(enhanced_visuals PRIVATE "IBM=1")
    set_target_properties(enhanced_visuals PROPERTIES OUTPUT_NAME "win")

    install(TARGETS enhanced_skyscapes RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/Enhanced Visuals")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_compile_definitions(enhanced_visuals PRIVATE "APL=1")
    set_target_properties(enhanced_visuals PROPERTIES OUTPUT_NAME "lin")

    install(TARGETS enhanced_visuals LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/Enhanced Visuals")
endif()