vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO wxWidgets/phoenix
    REF bfb335672e3fe0c75de645b7d859e558babfaca2
    SHA512 9dd40320c3be01f2db064a163503becd2ca861451237d44422dc2c0f242c0671f6c994e2c9ec0d9ac81ece2817788a1bc2973ccfdb98d458a7ae95090aadf66e
)

# We need a copy of the wxWidgets source code to build doxygen xml, the doxygen xml is used to generate the C++ code
# This should match the vcpkg port of wxWidgets
# THIS DOES NOT GET COMPILED
vcpkg_from_github(    
	OUT_SOURCE_PATH WX_SOURCE_PATH
    REPO wxWidgets/wxWidgets
    REF v3.1.4
    SHA512 108e35220de10afbfc58762498ada9ece0b3166f56a6d11e11836d51bfbaed1de3033c32ed4109992da901fecddcf84ce8a1ba47303f728c159c638dac77d148
    HEAD_REF master
)

find_program(GIT NAMES git git.cmd)

file(COPY ${WX_SOURCE_PATH}/	DESTINATION ${SOURCE_PATH}/ext/wxWidgets/)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})
file(COPY ${CMAKE_CURRENT_LIST_DIR}/cmake/ DESTINATION ${SOURCE_PATH}/cmake/)


# We need bash.exe for the wxPython preprocessor
if(CMAKE_HOST_WIN32)
	vcpkg_acquire_msys(MSYS_ROOT PACKAGES bash)
	vcpkg_add_to_path(PREPEND "${MSYS_ROOT}/usr/bin")
	
	set(PYTHON_ROOT "${_VCPKG_INSTALLED_DIR}/${TARGET_TRIPLET}/tools/python3")
	vcpkg_add_to_path(PREPEND "${PYTHON_ROOT}")
	
	set(ENV{PYTHONHOME} "${PYTHON_ROOT}")
	set(ENV{PYTHONPATH} "${PYTHON_ROOT}/DLLs;${PYTHON_ROOT}/Lib")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
	DISABLE_PARALLEL_CONFIGURE
)

vcpkg_install_cmake()

file(INSTALL ${SOURCE_PATH}/wx/ DESTINATION ${CURRENT_PACKAGES_DIR}/share/python3/Lib/site-packages/wx/)
file(INSTALL ${SOURCE_PATH}/wx/include/wxPython/ DESTINATION ${CURRENT_PACKAGES_DIR}/include/wxPython/)

# Per https://www.wxpython.org/pages/license/, using wxWindows Library License, no license in the source repo
file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/copyright DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})