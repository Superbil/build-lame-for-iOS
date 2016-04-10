#!/usr/bin/env bash

################################################################################
## Build-lame-for-iOS https://github.com/Superbil/build-lame-for-iOS
##
## Version 1.2
##
## Lastest Change:
## - Support Bitcode
## - Fix build simulator problem
##
## Release Library
## - Last library at https://github.com/Superbil/build-lame-for-iOS/releases/latest
##
## Requirements
## - Xcode 7
##
## Author: Superbil - https://github.com/superbil/
################################################################################

set -ev

# Min version for lame
MIN_VERSION="6.0"
# Set default output folder is build
OUTPUT_FOLDER=${OUTPUT-build}
# Set default make from Xcode
MAKE=${MAKE-$(xcrun --find make)}
# Set default compiler from Xcode
CC=${CC-$(xcrun --find gcc)}
# Set lipo from Xcode
LIPO=${LIPO-$(xcrun --find lipo)}

# Make output folder
mkdir -p $OUTPUT_FOLDER

function build_lame()
{
    if [ -f "Makefile" ];then
        ${MAKE} distclean
    fi

    # SDK must lower case
    _SDK=$(echo ${SDK} | tr '[:upper:]' '[:lower:]')
    SDK_ROOT=$(xcrun --sdk ${_SDK} --show-sdk-path)

    # C compiler flags
    # gcc in xcode is clang
    # Ref: http://clang.llvm.org/docs/CommandGuide/clang.html
    CFLAGS="-arch ${PLATFORM} -pipe -std=c99 ${BITCODE} -isysroot ${SDK_ROOT} -miphoneos-version-min=${MIN_VERSION}"

    # GNU Autoconf
    ./configure \
        CFLAGS="${CFLAGS}" \
        --host="${HOST}-apple-darwin" \
        --enable-static \
        --disable-decoder \
        --disable-frontend \
        --disable-debug \
        --disable-dependency-tracking

    ${MAKE}

    cp "libmp3lame/.libs/libmp3lame.a" "${OUTPUT_FOLDER}/libmp3lame-${PLATFORM}.a"
}

# Bulid simulator version
HOST="i686"
SDK="iPhoneSimulator"
BITCODE="-fembed-bitcode-marker"

PLATFORM="i386"
build_lame

PLATFORM="x86_64"
build_lame

# Build device version
HOST="arm"
SDK="iPhoneOS"
BITCODE="-fembed-bitcode"

PLATFORM="armv7"
build_lame

PLATFORM="armv7s"
build_lame

PLATFORM="arm64"
build_lame

# Remove old libmp3lame.a or lipo will failed
OUTPUT_LIB=${OUTPUT_FOLDER}/libmp3lame.a
if [ -f $OUTPUT_LIB ]; then
    rm $OUTPUT_LIB
fi

${LIPO} -create ${OUTPUT_FOLDER}/* -output ${OUTPUT_LIB}
