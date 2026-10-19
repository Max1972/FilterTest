#!/bin/bash
# Native macOS-only developer drop. Never installs the system-wide PKG.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    echo 'Run this script in a native Apple Silicon macOS Terminal (not Linux or Rosetta).' >&2
    exit 1
fi
for tool in cmake ctest xcrun pkgbuild productbuild hdiutil codesign pkgutil lipo shasum ditto auval python3; do
    command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done
xcrun --find clang++ >/dev/null
xcrun --show-sdk-path >/dev/null
BUILD="$ROOT/build-mac-test-drop"
DIST="$ROOT/dist"
NAME='OpenMB-v0.1.0-dev1-macOS-Monterey-arm64-UNSIGNED'
mkdir -p "$DIST"
DMG="$DIST/$NAME.dmg"
if [[ -e "$DMG" ]]; then
    echo "Output exists: $DMG. Move it aside before rebuilding." >&2
    exit 1
fi
WORK="$(mktemp -d "${TMPDIR:-/tmp}/openmb-drop.XXXXXX")"
VALIDATION_AU="$HOME/Library/Audio/Plug-Ins/Components/OpenMB.component"
COPIED_AU=0
MOUNTED=0
cleanup() {
    if [[ "$MOUNTED" == 1 ]]; then hdiutil detach "$WORK/mount" >/dev/null || true; fi
    if [[ "$COPIED_AU" == 1 ]]; then rm -rf "$VALIDATION_AU"; fi
    rm -rf "$WORK"
}
trap cleanup EXIT
cmake -S "$ROOT" -B "$BUILD" -DCMAKE_BUILD_TYPE=Release \
    -DOPENMB_BUILD_PLUGIN=ON -DBUILD_TESTING=ON -DOPENMB_SANITIZE=OFF \
    -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0
cmake --build "$BUILD" --config Release --parallel "${OPENMB_BUILD_JOBS:-4}"
ctest --test-dir "$BUILD" -C Release --output-on-failure
AU="$BUILD/OpenMB_artefacts/Release/AU/OpenMB.component"
[[ -d "$AU" ]] || { echo "Missing AU: $AU" >&2; exit 1; }
BINARY="$AU/Contents/MacOS/OpenMB"
[[ "$(lipo -archs "$BINARY")" == arm64 ]] || { echo 'Expected native arm64 AU' >&2; exit 1; }
# Inspect the actual linked binary, not just the CMake setting.
xcrun vtool -show-build "$BINARY" > "$WORK/build-version.txt"
python3 - "$WORK/build-version.txt" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
versions = re.findall(r'\bminos\s+(\d+(?:\.\d+)*)', s)
if not versions or any(tuple(map(int, v.split('.'))) > (12, 0, 0) for v in versions):
    sys.exit('AU minimum deployment target exceeds macOS 12.0 or could not be verified')
PY
# Ad-hoc signing checks local integrity; it is NOT Developer ID signing/notarization.
codesign --force --sign - "$AU"
codesign --verify --strict "$AU"
if [[ -e "$VALIDATION_AU" || -L "$VALIDATION_AU" ]]; then
    echo "Refusing to replace existing $VALIDATION_AU. Use a separate macOS test account." >&2
    exit 1
fi
if [[ -e /Library/Audio/Plug-Ins/Components/OpenMB.component ]]; then
    echo 'A system-wide OpenMB exists. Validate this drop in a separate disposable Mac environment.' >&2
    exit 1
fi
cat <<'TEXT'
Close Logic and other audio hosts before continuing.
For auval, this script will temporarily copy OpenMB.component into YOUR account's
~/Library/Audio/Plug-Ins/Components, then remove that temporary copy on exit.
The PKG will NOT be installed. Type VALIDATE to allow this temporary copy:
TEXT
read -r reply
[[ "$reply" == VALIDATE ]] || { echo 'Validation cancelled; no DMG produced.' >&2; exit 1; }
mkdir -p "$(dirname "$VALIDATION_AU")"
COPIED_AU=1
ditto "$AU" "$VALIDATION_AU"
auval -v aufx Omb1 Opmb 2>&1 | tee "$WORK/auval.txt"
grep -q 'AU VALIDATION SUCCEEDED' "$WORK/auval.txt" || { echo 'auval did not report success' >&2; exit 1; }
rm -rf "$VALIDATION_AU"
COPIED_AU=0
PAYLOAD="$WORK/payload"
CONTENTS="$WORK/contents"
mkdir -p "$PAYLOAD/Library/Audio/Plug-Ins/Components" "$CONTENTS" "$WORK/resources"
ditto "$AU" "$PAYLOAD/Library/Audio/Plug-Ins/Components/OpenMB.component"
cat > "$CONTENTS/README.txt" <<'TEXT'
OpenMB 0.1.0-dev1 — UNSIGNED DEVELOPMENT DROP
Native arm64. Minimum macOS Monterey 12.0.
This is a fixed full-band compressor skeleton, NOT the specified six-band OpenMB.
No adjustable parameters, presets, phase modes, or finished UI are included.
Use a disposable macOS environment/account and a test Logic project.
Install OpenMB.pkg writes /Library/Audio/Plug-Ins/Components/OpenMB.component.
It requires administrator approval. Close all audio hosts first.
The AU is ad-hoc signed, not Developer ID signed. The PKG/DMG are unsigned and
not notarized. Gatekeeper may block installation. Do not disable Gatekeeper.
Use Apple's per-item Privacy & Security / Open Anyway flow only if offered and
only after verifying this artifact's origin. Managed Macs may forbid this.
If blocked, stop and use a properly signed/notarized build instead.
User presets are not installed or deleted by this development drop.
Manual removal: remove only /Library/Audio/Plug-Ins/Components/OpenMB.component
with administrator approval, then reopen Logic. The receipt is com.openmb.audio.au.
No isolated PKG installation, uninstall, or Logic test is claimed by the builder.
TEXT
cat > "$CONTENTS/Release Notes.txt" <<'TEXT'
OpenMB 0.1.0-dev1
Initial native AU skeleton and portable dynamics library.
Fixed full-band downward compression: -24 dB threshold, 4:1 ratio,
6 dB knee, 10 ms attack, 100 ms release, linked peak detector.
Generic empty editor. No exposed controls, multiband processing, phase engines,
external sidechain, presets, or stateful settings yet.
Not a production release. See README.txt before installing.
TEXT
cp "$ROOT/scripts/Uninstall OpenMB.command" "$CONTENTS/Uninstall OpenMB.command"
chmod 755 "$CONTENTS/Uninstall OpenMB.command"
cp "$CONTENTS/README.txt" "$WORK/resources/introduction.txt"
pkgbuild --root "$PAYLOAD" --identifier com.openmb.audio.au --version 0.1.0 \
    --install-location / --ownership recommended "$WORK/OpenMB-component.pkg"
cat > "$WORK/Distribution.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>OpenMB 0.1.0-dev1 — UNSIGNED</title>
  <options customize="never" require-scripts="false" hostArchitectures="arm64"/>
  <volume-check><allowed-os-versions><os-version min="12.0"/></allowed-os-versions></volume-check>
  <domains enable_localSystem="true" enable_currentUserHome="false" enable_anywhere="false"/>
  <welcome file="introduction.txt"/>
  <choices-outline><line choice="default"/></choices-outline>
  <choice id="default" visible="false"><pkg-ref id="com.openmb.audio.au"/></choice>
  <pkg-ref id="com.openmb.audio.au" version="0.1.0" onConclusion="none">OpenMB-component.pkg</pkg-ref>
</installer-gui-script>
XML
productbuild --distribution "$WORK/Distribution.xml" --resources "$WORK/resources" \
    --package-path "$WORK" "$CONTENTS/Install OpenMB.pkg"
pkgutil --expand-full "$CONTENTS/Install OpenMB.pkg" "$WORK/expanded-pkg"
pkgutil --payload-files "$WORK/OpenMB-component.pkg" > "$WORK/payload-list.txt"
grep -q 'Library/Audio/Plug-Ins/Components/OpenMB.component/Contents/MacOS/OpenMB' "$WORK/payload-list.txt"
hdiutil create -volname 'OpenMB 0.1.0-dev1 UNSIGNED' -srcfolder "$CONTENTS" -format UDZO "$DMG"
[[ -s "$DMG" ]]
hdiutil verify "$DMG"
mkdir -p "$WORK/mount"
hdiutil attach "$DMG" -readonly -nobrowse -mountpoint "$WORK/mount"
MOUNTED=1
for item in 'Install OpenMB.pkg' README.txt 'Release Notes.txt' 'Uninstall OpenMB.command'; do
    [[ -s "$WORK/mount/$item" ]] || { echo "Missing DMG item: $item" >&2; exit 1; }
done
hdiutil detach "$WORK/mount"
MOUNTED=0
(cd "$DIST" && shasum -a 256 "$NAME.dmg" > "$NAME-SHA256.txt")
cp "$WORK/auval.txt" "$DIST/$NAME-auval.txt"
python3 - "$DMG" "$DIST/$NAME-manifest.json" <<'PY'
import hashlib, json, pathlib, sys
p = pathlib.Path(sys.argv[1])
manifest = dict(version='0.1.0-dev1', artifact=p.name, bytes=p.stat().st_size,
 sha256=hashlib.sha256(p.read_bytes()).hexdigest(), architecture='arm64',
 minimum_macos='12.0', auval='passed', portable_tests='passed',
 dmg_mount='passed', payload_inspection='passed', signing='ad-hoc AU only',
 notarization='not performed', logic_testing='unverified',
 pkg_installation='unverified', uninstall_testing='unverified')
pathlib.Path(sys.argv[2]).write_text(json.dumps(manifest, indent=2)+'\n')
PY
printf '\nCreated unsigned development DMG: %s\n' "$DMG"
cat "$DIST/$NAME-SHA256.txt"
