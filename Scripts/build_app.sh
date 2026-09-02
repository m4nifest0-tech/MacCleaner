#!/bin/bash
# Compila PuliziaMac e lo impacchetta in un vero bundle .app (senza Xcode).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CONFIG="release"
APP_NAME="PuliziaMac"
BUNDLE_ID="it.rpm2000.PuliziaMac"
BUILD_DIR="$ROOT_DIR/.build/$CONFIG"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"

echo "==> swift build -c $CONFIG"
swift build -c "$CONFIG"

echo "==> Assemblo $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

if [ -f "$ROOT_DIR/Sources/PuliziaMac/Resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Sources/PuliziaMac/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Logo per l'intestazione del PDF esportato (opzionale: l'export funziona anche senza).
if [ -f "$ROOT_DIR/Sources/PuliziaMac/Resources/Logo.jpeg" ]; then
  cp "$ROOT_DIR/Sources/PuliziaMac/Resources/Logo.jpeg" "$APP_BUNDLE/Contents/Resources/Logo.jpeg"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

echo "==> Firma ad-hoc"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Comprimo per la release"
ZIP_PATH="$ROOT_DIR/dist/$APP_NAME.app.zip"
rm -f "$ZIP_PATH"
(cd "$ROOT_DIR/dist" && ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$APP_NAME.app.zip")

echo "==> Fatto: $APP_BUNDLE"
echo "Avvia con: open \"$APP_BUNDLE\""
echo "Asset per la release: $ZIP_PATH"
