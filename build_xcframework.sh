#!/bin/bash

set -e

# Define variables
FRAMEWORK_NAME="GRDB"
SCHEME_NAME="GRDB"
OUTPUT_PATH="./XCFramework"

# Remove existing XCFramework
rm -rf "${OUTPUT_PATH}"
mkdir -p "${OUTPUT_PATH}"

# Function to build for a specific platform
build_for_platform() {
    local platform=$1
    local sdk=$2
    local archive_path="${OUTPUT_PATH}/${platform}.xcarchive"

    echo "Building for ${platform}..."
    xcodebuild archive \
        -project "GRDB.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -archivePath "${archive_path}" \
        -sdk "${sdk}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
}

# Build for each platform
build_for_platform "iOS" "iphoneos"
build_for_platform "iOS_Simulator" "iphonesimulator"
build_for_platform "macOS" "macosx"

# Create XCFramework
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "${OUTPUT_PATH}/iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${OUTPUT_PATH}/iOS_Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${OUTPUT_PATH}/macOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${OUTPUT_PATH}/${FRAMEWORK_NAME}.xcframework"

# Clean up intermediate archives
rm -rf "${OUTPUT_PATH}/iOS.xcarchive"
rm -rf "${OUTPUT_PATH}/iOS_Simulator.xcarchive"
rm -rf "${OUTPUT_PATH}/macOS.xcarchive"

echo "XCFramework created at ${OUTPUT_PATH}/${FRAMEWORK_NAME}.xcframework"

# After creating the XCFramework, zip it
timestap=$(date +%s) # get rid of CDN caching
ZIP_NAME="${FRAMEWORK_NAME}-${timestap}.xcframework.zip"
(cd ${OUTPUT_PATH} && zip -r ../"${ZIP_NAME}" "${FRAMEWORK_NAME}.xcframework")

# Generate checksum using swift package
CHECKSUM=$(swift package compute-checksum "${ZIP_NAME}")

echo "XCFramework zipped as ${ZIP_NAME}"
echo "Checksum: ${CHECKSUM}"
