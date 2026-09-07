#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p "lumi2.app/Contents/MacOS" "lumi2.app/Contents/Resources" .build/module-cache
xcrun swiftc Source/main.swift -O -target arm64-apple-macosx13.0 -module-cache-path .build/module-cache -o lumi2.app/Contents/MacOS/Lumitime -framework Cocoa
cp Assets/Lumitime.icns lumi2.app/Contents/Resources/Lumitime.icns
cat > lumi2.app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Lumitime</string>
<key>CFBundleIdentifier</key><string>local.lumitime.lumi2</string>
<key>CFBundleName</key><string>lumi2</string>
<key>CFBundleDisplayName</key><string>lumi2</string>
<key>CFBundleIconFile</key><string>Lumitime.icns</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - lumi2.app
echo "Built lumi2.app"
