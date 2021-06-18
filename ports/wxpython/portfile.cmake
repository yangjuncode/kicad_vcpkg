vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO wxWidgets/phoenix
    REF 64e5d863f7833f10df6a0fbcf3221a730562224b
    SHA512 6501e354b70e125d8bb5bcaffe4cdb831dd6169b9696e0696b3c87f012e975480c098b3436bb3edbe09feb7f91accecd8a311c0feb6ad99db586acd39d489109
    PATCHES
        remove-webkit.patch
		typedefs.patch
		Disable-webview-GetVersionInfo.patch
)

# We need a copy of the wxWidgets source code to build doxygen xml, the doxygen xml is used to generate the C++ code
# This should match the vcpkg port of wxWidgets
# THIS DOES NOT GET COMPILED
vcpkg_from_github(    
	OUT_SOURCE_PATH WX_SOURCE_PATH
    REPO wxWidgets/wxWidgets
    REF 9c0a8be1dc32063d91ed1901fd5fcd54f4f955a1 #v3.1.5
    SHA512 33817f766b36d24e5e6f4eb7666f2e4c1ec305063cb26190001e0fc82ce73decc18697e8005da990a1c99dc1ccdac9b45bb2bbe5ba73e6e2aa860c768583314c
    HEAD_REF master
    PATCHES
        fix-wxwidgets-wxconfigbase-interface.patch
		remove-low-quality-dup.patch
		restore-objectptr-const.patch
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


find_package( Python3 COMPONENTS Interpreter REQUIRED )

vcpkg_execute_build_process(
    COMMAND ${Python3_EXECUTABLE} -m ensurepip
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "prepare-ensurepip-${RELEASE_TRIPLET}"
)

vcpkg_execute_build_process(
    COMMAND ${Python3_EXECUTABLE} -m pip install -r ${SOURCE_PATH}/requirements.txt
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "prepare-requirements-${RELEASE_TRIPLET}"
)

vcpkg_execute_build_process(
    COMMAND ${Python3_EXECUTABLE} ./build.py dox
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "prepare-dox-${RELEASE_TRIPLET}"
)

vcpkg_execute_build_process(
    COMMAND ${Python3_EXECUTABLE} ./build.py etg --nodoc sip
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "prepare-etg-${RELEASE_TRIPLET}"
)


vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

vcpkg_install_cmake()

file(INSTALL ${SOURCE_PATH}/wx/ DESTINATION ${CURRENT_PACKAGES_DIR}/tools/python3/Lib/site-packages/wx/)
file(INSTALL ${SOURCE_PATH}/wx/include/wxPython/ DESTINATION ${CURRENT_PACKAGES_DIR}/include/wxPython/)

# Per https://www.wxpython.org/pages/license/, using wxWindows Library License, no license in the source repo
file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/copyright DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})