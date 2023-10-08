cmake_minimum_required(VERSION 3.20)

project("Enhanced Visuals")

function(add_resource resource destination)
    configure_file("${resource}" "${destination}/${resource}" COPYONLY)
    install(FILES "${resource}" DESTINATION "${CMAKE_INSTALL_PREFIX}/${destination}")
endfunction()

add_resource("share/vertex_shader.glsl" "Enhanced Visuals")
add_resource("share/fragment_shader.glsl" "Enhanced Visuals")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

add_library(enhanced_visuals MODULE "src/enhanced_visuals.cpp")

set(XP12_SDK_DIRECTORY "" CACHE PATH "X-Plane 12 SDK directory")

if (XP12_SDK_DIRECTORY STREQUAL "")
    message(FATAL_ERROR "X-Plane 12 SDK directory is not set!")
endif()

find_package(OpenGL REQUIRED)

find_package(glbinding REQUIRED)
find_package(globjects REQUIRED)

find_package(glm REQUIRED)

target_include_directories(enhanced_visuals PRIVATE "${XP12_SDK_DIRECTORY}/CHeaders/XPLM" glm::glm)
target_compile_definitions(enhanced_visuals PRIVATE "XPLM400=1" "XPLM303=1" "XPLM301=1" "XPLM300=1" "XPLM210=1" "XPLM200=1")
target_link_libraries(enhanced_visuals PRIVATE OpenGL::GL glbinding::glbinding globjects::globjects)

set_target_properties(enhanced_visuals PROPERTIES PREFIX "")
set_target_properties(enhanced_visuals PROPERTIES SUFFIX ".xpl")

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_compile_definitions(enhanced_visuals PRIVATE "IBM=1")
    target_link_libraries(enhanced_visuals PRIVATE "${XP12_SDK_DIRECTORY}/Libraries/Win/XPLM_64.lib")
    
    set_target_properties(enhanced_visuals PROPERTIES LIBRARY_OUTPUT_NAME "win")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_compile_definitions(enhanced_visuals PRIVATE "LIN=1")
    set_target_properties(enhanced_visuals PROPERTIES LIBRARY_OUTPUT_NAME "lin")
endif()

set_target_properties(enhanced_visuals PROPERTIES LIBRARY_OUTPUT_DIRECTORY "Enhanced Visuals")
install(TARGETS enhanced_visuals LIBRARY DESTINATION "${CMAKE_INSTALL_PREFIX}/Enhanced Visuals")
