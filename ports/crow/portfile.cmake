vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO CrowCpp/crow
    REF 7e47d4c7ee548c5fd954efd82cfeed330a7823ea #0.3+2
    SHA512 47822ccdfb259a65bde8fed0c29bb8e58bc2f29896ff186c03098eb897985307e7477aa03808a42db01df245054411f05f95c6d9ae6477d75dd94399af3bb130
    FILE_DISAMBIGUATOR 1
    HEAD_REF master
)

file(INSTALL "${SOURCE_PATH}/include/" DESTINATION "${CURRENT_PACKAGES_DIR}/include")
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
