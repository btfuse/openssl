
#!/bin/bash

# Copyright 2023-2024 Breautek 

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Purpose
#
# Builds and prepares the project for release.
# If you're developing or contributing to the Fuse framework, you'll want to open
# the XCWorkspace in XCode instead.
#
# This script will 
#   1.  Clean your build environment for a fresh build.
#   2.  Run tests, this may take awhile.
#   3.  Copy files to a dist/ directory.

source build-tools/assertions.sh
source build-tools/DirectoryTools.sh
source build-tools/Checksum.sh

assertMac "Mac is required to build Fuse OpenSSL iOS"

VERSION=$(< VERSION)
BUILD_NO=$(< BUILD)

echo "Building Fuse OpenSSL iOS Library $VERSION..."

rm -rf dist
mkdir -p dist

echo "Cleaning the workspace..."
# Clean the build
# XCode can do a poor job in detecting if object code should recompile, particularly when messing with
# build configuration settings. This will ensure that the produced binary will be representative.
xcodebuild -quiet -workspace OpenSSL.xcworkspace -scheme OpenSSL -configuration Release -destination "generic/platform=iOS" clean
assertLastCall
xcodebuild -quiet -workspace OpenSSL.xcworkspace -scheme OpenSSL -configuration Debug -destination "generic/platform=iOS Simulator" clean
assertLastCall

echo "Building iOS library..."
# Now build the iOS platform target in Release mode. We will continue to use Debug mode for iOS Simulator targets.
xcodebuild -quiet -workspace OpenSSL.xcworkspace -scheme OpenSSL -configuration Release -destination "generic/platform=iOS" build
assertLastCall
echo "Building iOS Simulator library..."
xcodebuild -quiet -workspace OpenSSL.xcworkspace -scheme OpenSSL -configuration Debug -destination "generic/platform=iOS Simulator" build
assertLastCall

iosBuild=$(echo "$(xcodebuild -workspace OpenSSL.xcworkspace -scheme OpenSSL -configuration Release -sdk iphoneos -showBuildSettings | grep "CONFIGURATION_BUILD_DIR")" | cut -d'=' -f2 | xargs)
simBuild=$(echo "$(xcodebuild -workspace OpenSSL.xcworkspace -scheme OpenSSL -configuration Debug -sdk iphonesimulator -showBuildSettings | grep "CONFIGURATION_BUILD_DIR")" | cut -d'=' -f2 | xargs)

# OpenSSL dependency seems to modify their git working state on builds, which will prevent our release scripts, so
# so we will clean their checkout after builds
spushd third_party/openssl/cloudflare-quiche
    git checkout -- .
spopd

echo $iosBuild

echo "Packing XCFramework..."
xcodebuild -create-xcframework \
    -library $iosBuild/libopenssl.a -headers $iosBuild/openssl/include \
    -library $simBuild/libopenssl.a -headers $simBuild/openssl/include \
    -output dist/OpenSSL.xcframework
assertLastCall
cp LICENSE dist/OpenSSL.xcframework/LICENSE

spushd dist
    zip -r OpenSSL.xcframework.zip OpenSSL.xcframework > /dev/null
    sha1_compute OpenSSL.xcframework.zip
spopd

OPENSSL_CHECKSUM=$(cat ./dist/OpenSSL.xcframework.zip.sha1.txt)

echo "Checksum: $OPENSSL_CHECKSUM"

podSpecTemplate=$(<OpenSSL.podspec.template)

podSpecTemplate=${podSpecTemplate//\$VERSION\$/$VERSION}
podSpecTemplate=${podSpecTemplate//\$CHECKSUM\$/$OPENSSL_CHECKSUM}

# Write out the resolved template
echo "$podSpecTemplate" > OpenSSL.podspec
