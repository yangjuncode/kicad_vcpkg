cmake_minimum_required(VERSION 3.14)
# Minimum 3.12 required for CONFIGURE_DEPENDS

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

project( wxpython )

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set(WXPYTHON_SIP_DIR ${PROJECT_SOURCE_DIR}/sip)
set(WXPYTHON_SRC_DIR ${PROJECT_SOURCE_DIR}/src)
set(WXPYTHON_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/src)
set(WXPYTHON_WXP_INCLUDE_DIR ${PROJECT_SOURCE_DIR}/wx/include)
set(WXPYTHON_OUT_DIR ${PROJECT_SOURCE_DIR}/wx)

## Create __version__.py
set(VERSION_STRING "foo")
set(VERSION_MAJOR 4)
set(VERSION_MINOR 1)
set(VERSION_RELEASE 0)
set(VERSION_BUILD_TYPE ${CMAKE_BUILD_TYPE})
configure_file( "${PROJECT_SOURCE_DIR}/cmake/__version__.py.in" "${WXPYTHON_OUT_DIR}/__version__.py" @ONLY )


add_definitions(-DSIP_MODULE_NAME=wx.siplib -DSIP_MODULE_BASENAME=siplib)
add_definitions(-DUNICODE -D_UNICODE -DUTF8)
add_definitions(-D_WINDOWS -DWIN32 -D__WXMSW__ -DWXUSINGDLL=1 -DISOLATION_AWARE_ENABLED)

if(VCPKG_TOOLCHAIN)
	#This is a silly hack to convince the cmake helper to look in /debug/lib for the debug library
	#or else it wont it
	set( Python3_FIND_REGISTRY NEVER )
	foreach(root in ${CMAKE_FIND_ROOT_PATH})
		list(APPEND PYTHON3_ROOT_HINTS "${root}/lib")
	endforeach()
	set( Python3_ROOT_DIR  ${PYTHON3_ROOT_HINTS} )
endif()
find_package( Python3 COMPONENTS Interpreter Development REQUIRED )

find_package( wxWidgets COMPONENTS gl aui adv html core net base propgrid media xml ribbon richtext webview webkit xrc stc REQUIRED )

add_custom_target(
    pyrequirements
	COMMAND ${Python3_EXECUTABLE} -m ensurepip && ${Python3_EXECUTABLE} -m pip install -r ${PROJECT_SOURCE_DIR}/requirements.txt
)

# wxPython uses doxygen xml to generate the later sip modules
add_custom_target(
    dox ALL
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMAND ${Python3_EXECUTABLE} ./build.py dox
)

add_dependencies( dox pyrequirements )

# Run the sip generation, delete files first or they don't get updated!
add_custom_target(
    sipgen ALL
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMAND ${Python3_EXECUTABLE} ./build.py etg --nodoc sip
)
add_dependencies( sipgen pyrequirements dox )


set(SIPLIB_SRCS 
    ${WXPYTHON_SIP_DIR}/siplib/apiversions.c
    ${WXPYTHON_SIP_DIR}/siplib/array.c
    ${WXPYTHON_SIP_DIR}/siplib/bool.cpp
    ${WXPYTHON_SIP_DIR}/siplib/descriptors.c
    ${WXPYTHON_SIP_DIR}/siplib/int_convertors.c
    ${WXPYTHON_SIP_DIR}/siplib/objmap.c
    ${WXPYTHON_SIP_DIR}/siplib/qtlib.c
    ${WXPYTHON_SIP_DIR}/siplib/siplib.c
    ${WXPYTHON_SIP_DIR}/siplib/threads.c
    ${WXPYTHON_SIP_DIR}/siplib/voidptr.c
)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
	set(OUTPUT_PREFIX "_d.pyd")
else()
	set(OUTPUT_PREFIX ".pyd")
endif()

add_library(siplib SHARED ${SIPLIB_SRCS})
target_include_directories( siplib PUBLIC ${Python3_INCLUDE_DIRS} )
target_link_libraries( siplib PUBLIC ${Python3_LIBRARIES} )
set_target_properties( siplib PROPERTIES 
    OUTPUT_NAME siplib 
    SUFFIX      ${OUTPUT_PREFIX}
    )
add_dependencies( siplib sipgen )
install(TARGETS siplib RUNTIME DESTINATION ${WXPYTHON_OUT_DIR})

function(build_wxp_pyd lib_name link_libs_extra glob)
	#ensure at least a empty cpp file exists for the lib, even with CONFIGURE_DEPENDS we need a first time glob to work 
	file(TOUCH ${WXPYTHON_SIP_DIR}/cpp/sip_${lib_name}.cpp)

    if(${glob})
        file(GLOB SRCS CONFIGURE_DEPENDS ${glob} )
    else()
        file(GLOB SRCS CONFIGURE_DEPENDS ${WXPYTHON_SIP_DIR}/cpp/sip_${lib_name}*.cpp )
    endif()
    add_library( ${lib_name} SHARED ${SRCS} )
    target_include_directories( ${lib_name} PUBLIC ${WXPYTHON_SIP_DIR}/siplib ${WXPYTHON_SRC_DIR} ${WXPYTHON_WXP_INCLUDE_DIR} ${Python3_INCLUDE_DIRS} ${wxWidgets_INCLUDE_DIRS} )
    add_dependencies( ${lib_name} siplib sipgen dox )
    target_link_libraries( ${lib_name}
                            siplib 
                            ${Python3_LIBRARIES} 
                            ${wxWidgets_LIBRARIES}
                            ${link_libs_extra} )

    set_target_properties( ${lib_name} PROPERTIES 
        OUTPUT_NAME _${lib_name}
        SUFFIX      ${OUTPUT_PREFIX}
    )

    install(TARGETS ${lib_name} RUNTIME DESTINATION ${WXPYTHON_OUT_DIR})
endfunction()

build_wxp_pyd(core "" "" "")
build_wxp_pyd(adv "core" "core" "")
build_wxp_pyd(aui "core" "core" "")
build_wxp_pyd(dataview "core" "core" "")
build_wxp_pyd(glcanvas "core" "core" "")
build_wxp_pyd(grid "core" "core" "")
build_wxp_pyd(html "core" "core" "${WXPYTHON_SIP_DIR}/cpp/sip_html[!2]*.cpp")
build_wxp_pyd(html2 "core" "core" "")
build_wxp_pyd(media "core" "core" "")
build_wxp_pyd(msw "core" "core" "")
build_wxp_pyd(propgrid "core" "core" "")
build_wxp_pyd(ribbon "core" "core" "")
build_wxp_pyd(richtext "core" "core" "")
build_wxp_pyd(stc "core" "core" "")
build_wxp_pyd(webkit "core" "core" "")
build_wxp_pyd(xml "core" "core" "")
build_wxp_pyd(xrc "core" "core" "")
