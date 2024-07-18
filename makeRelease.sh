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

source build-tools/assertions.sh
source build-tools/DirectoryTools.sh

assertMac "Mac is required for publishing"
assertGitRepo
assertCleanRepo

VERSION="$1"

assertVersion $VERSION
assetGitTagAvailable "$VERSION"

echo $VERSION > VERSION
BUILD_NO=$(< BUILD)
BUILD_NO=$((BUILD_NO + 1))
echo $BUILD_NO > BUILD

./build.sh

git add VERSION BUILD
git commit -m "Release: $VERSION"
git push
git tag -a $VERSION -m "Release: $VERSION"
git push --tags

gh release create $VERSION \
    ./dist/OpenSSL.xcframework.zip \
    ./dist/OpenSSL.xcframework.zip.sha1.txt \
    --verify-tag --generate-notes

pod spec lint OpenSSL.podspec
assertLastCall

pod repo push breautek OpenSSL.podspec
