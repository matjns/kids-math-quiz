#!/usr/bin/env bash
# Build Math Quiz into build/Math Quiz.app, then zip it.
# On a Mac: ./build.sh
# Anywhere Swift is installed: ./build.sh test
set -euo pipefail
cd "$(dirname "$0")"

if [[ "${1:-}" == "test" ]]; then
  swift test
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Math Quiz has to be built on a Mac."
  echo "This computer is $(uname -s). Copy the project to the Mac and run ./build.sh there."
  echo "The logic tests can run on this computer with: ./build.sh test"
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift isn't installed."
  echo "Install Xcode from the App Store, open it once so it can finish setup, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi

if ! xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1; then
  echo "The macOS SDK is missing."
  echo "Install Xcode from the App Store, open it once, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi

export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-14.0}"

ICON_SRC="Packaging/Assets.xcassets/AppIcon.appiconset"
if [[ ! -f "$ICON_SRC/Contents.json" || ! -f "$ICON_SRC/icon_512x512@2x.png" ]]; then
  echo "The app icon is missing from Packaging/Assets.xcassets."
  exit 1
fi

echo "Building Math Quiz (release, Apple silicon and Intel)..."
# Repeated --arch flags ask Swift to write one universal binary.
ARCH_FLAGS=(--arch arm64 --arch x86_64)
swift build -c release --product MathQuiz "${ARCH_FLAGS[@]}"
BIN_DIR="$(swift build -c release --product MathQuiz "${ARCH_FLAGS[@]}" --show-bin-path)"
if [[ ! -x "$BIN_DIR/MathQuiz" ]]; then
  echo "The build finished but did not produce $BIN_DIR/MathQuiz."
  exit 1
fi

APP="build/Math Quiz.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MathQuiz" "$APP/Contents/MacOS/MathQuiz"
cp "Packaging/Info.plist" "$APP/Contents/Info.plist"
cp "Packaging/PrivacyInfo.xcprivacy" "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
chmod 755 "$APP/Contents/MacOS/MathQuiz"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
cp "$ICON_SRC"/icon_*.png "$ICONSET/"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

echo "Compiling the icon asset catalog..."
xcrun actool \
  --compile "$APP/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$WORK/PartialInfo.plist" \
  "$PWD/Packaging/Assets.xcassets"

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP" || true
fi

# Ad-hoc signature so the sandbox entitlement is actually on the app.
# This is not an Apple Developer ID signature. Gatekeeper will still warn.
codesign --force --sign - \
  --identifier com.kidscomputer.mathquiz \
  --entitlements Packaging/MathQuiz.entitlements \
  "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
if ! codesign -d --entitlements :- "$APP" 2>&1 | grep -q "com.apple.security.app-sandbox"; then
  echo "The sandbox entitlement was not sealed into Math Quiz.app."
  exit 1
fi

ARCHS="$(lipo -archs "$APP/Contents/MacOS/MathQuiz")"
echo "Architectures: ${ARCHS}"
if [[ "$ARCHS" != *arm64* || "$ARCHS" != *x86_64* ]]; then
  echo "Math Quiz needs both Apple silicon (arm64) and Intel (x86_64)."
  echo "This build only has: ${ARCHS}"
  exit 1
fi

LINKED="$(otool -L "$APP/Contents/MacOS/MathQuiz")"
echo "$LINKED"
if echo "$LINKED" | grep -q '@rpath/libswift'; then
  echo "The app is linked to the Swift toolchain, so it will not open on another Mac."
  echo "Install Xcode, then point the tools at it:"
  echo "  sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi

mkdir -p dist
rm -f "dist/MathQuiz-mac-universal.zip"
ditto -c -k --keepParent "$APP" "dist/MathQuiz-mac-universal.zip"
cp README-mac.txt dist/README-mac.txt

echo
echo "Built: $APP"
echo "Zip: dist/MathQuiz-mac-universal.zip"
echo "Bundle id: com.kidscomputer.mathquiz"
echo "Copy Math Quiz.app to /Applications."
echo "Kids Computer opens it from the Math Quiz tile, using that bundle id."
