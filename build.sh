#!/bin/bash

VERSION=$(cat AudioUnitInfo.xcodeproj/project.pbxproj | \
          grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | \
          tr -d ';' | tr -d ' ')
ARCHIVE_DIR=/Users/Larry/Library/Developer/Xcode/Archives/CommandLine

rm -f make.log
touch make.log
rm -rf build

echo "Building AudioUnitInfo" 2>&1 | tee -a make.log

xcodebuild -project AudioUnitInfo.xcodeproj clean 2>&1 | tee -a make.log
xcodebuild -project AudioUnitInfo.xcodeproj \
    -scheme "AudioUnitInfo Release" -archivePath AudioUnitInfo.xcarchive \
    archive 2>&1 | tee -a make.log

rm -rf ${ARCHIVE_DIR}/AudioUnitInfo-v${VERSION}.xcarchive
cp -rf AudioUnitInfo.xcarchive \
    ${ARCHIVE_DIR}/AudioUnitInfo-v${VERSION}.xcarchive

