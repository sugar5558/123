#!/bin/bash

echo "📦 开始构建..."

mkdir -p Payload/KFD_CF_Mod.app

cat > Payload/KFD_CF_Mod.app/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>KFD_CF_Mod</string>
    <key>CFBundleIdentifier</key>
    <string>com.kfd.cfmod</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>KFD_CF_Mod</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
EOF

clang -o Payload/KFD_CF_Mod.app/KFD_CF_Mod \
    -framework UIKit \
    -framework Foundation \
    -framework MachO \
    -ObjC \
    -x objective-c \
    -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
    -target arm64-apple-ios15.0 \
    -fobjc-arc \
    main.m

if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
    zip -r KFD_CF_Mod.ipa Payload
    echo "✅ IPA 打包完成"
else
    echo "❌ 编译失败"
    exit 1
fi
