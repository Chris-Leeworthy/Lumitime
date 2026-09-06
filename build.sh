#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p "Lumitime.app/Contents/MacOS" "Lumitime.app/Contents/Resources" .build/module-cache
xcrun swiftc Source/main.swift -O -target arm64-apple-macosx13.0 -module-cache-path .build/module-cache -o Lumitime.app/Contents/MacOS/Lumitime -framework Cocoa
cat > Lumitime.app/Contents/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Lumitime</string>
<key>CFBundleIdentifier</key><string>local.lumitime.clock</string>
<key>CFBundleName</key><string>Lumitime</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - Lumitime.app
echo "Built Lumitime.app"
