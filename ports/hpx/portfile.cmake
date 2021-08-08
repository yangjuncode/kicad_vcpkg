
vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO STEllAR-GROUP/hpx
    REF 1.7.0
    SHA512 052b3278710d8047c8e0e0979a668aa5161c495fcd12b089dd5039c64bd414b4ec0b96dfcd414d68e0db5b31c360dffb84374413c53794f37ce77d9cabc89518
    HEAD_REF stable
    PATCHES
        hpx-1.7.0-format-from-string.patch
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DHPX_WITH_VCPKG=ON
        -DHPX_WITH_TESTS=OFF
        -DHPX_WITH_EXAMPLES=OFF
        -DHPX_WITH_TOOLS=OFF
        -DHPX_WITH_RUNTIME=OFF
)

vcpkg_install_cmake()

# post build cleanup
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/HPX)

file(GLOB_RECURSE CMAKE_FILES "${CURRENT_PACKAGES_DIR}/share/hpx/*.cmake")
foreach(CMAKE_FILE IN LISTS CMAKE_FILES)
    file(READ ${CMAKE_FILE} _contents)
    string(REGEX REPLACE
        "lib/([A-Za-z0-9_.-]+\\.dll)"
        "bin/\\1"
        _contents "${_contents}")
    string(REGEX REPLACE
        "lib/hpx/([A-Za-z0-9_.-]+\\.dll)"
        "bin/hpx/\\1"
        _contents "${_contents}")
    file(WRITE ${CMAKE_FILE} "${_contents}")
endforeach()

vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/HPXConfig.cmake"
    "set(HPX_BUILD_TYPE \"Release\")"
    "set(HPX_BUILD_TYPE \"\${CMAKE_BUILD_TYPE}\")")

vcpkg_replace_string(
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/HPXMacros.cmake"
    "set(CMAKE_MODULE_PATH \${CMAKE_MODULE_PATH}"
    "list(APPEND CMAKE_MODULE_PATH")

file(INSTALL
    ${SOURCE_PATH}/LICENSE_1_0.txt
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

file(GLOB DLLS ${CURRENT_PACKAGES_DIR}/lib/*.dll)
if(DLLS)
    file(COPY ${DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(REMOVE ${DLLS})
endif()

file(GLOB DLLS ${CURRENT_PACKAGES_DIR}/lib/hpx/*.dll)
if(DLLS)
    file(COPY ${DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/bin/hpx)
    file(REMOVE ${DLLS})
endif()

file(GLOB DLLS ${CURRENT_PACKAGES_DIR}/debug/lib/*.dll)
if(DLLS)
    file(COPY ${DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(REMOVE ${DLLS})
endif()

file(GLOB DLLS ${CURRENT_PACKAGES_DIR}/debug/lib/hpx/*.dll)
if(DLLS)
    file(COPY ${DLLS} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin/hpx)
    file(REMOVE ${DLLS})
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/cmake)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/lib/pkgconfig)

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig)

vcpkg_copy_pdbs()
