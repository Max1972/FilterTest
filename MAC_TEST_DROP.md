# Build the first development DMG on your M1 Pro

This is an early fixed full-band compressor skeleton, not the completed OpenMB
specification. Expect an empty generic editor, no adjustable controls, no presets,
and none of the multiband or phase engines. Test with a new disposable Logic
project, low monitoring levels, and a duplicate audio file.

## 1. Get the source

Download and extract the supplied OpenMB-source-dev1.tar.gz. The files are inside
OpenMB-source-dev1/. This archive includes the build scripts; no Git checkout is
required. Alternatively use a checkout containing these files. Cloud changes
have not been pushed to GitHub automatically.

## 2. Prepare your Mac

Use a native Terminal, not Terminal running under Rosetta. Confirm:

```sh
uname -m
sw_vers -productVersion
```

Expect arm64 and macOS 12.0 or newer. Install Apple's Command Line Tools:

```sh
xcode-select --install
```

If already installed, macOS reports that. Alternatively use a full Xcode version
compatible with your installed macOS. Confirm the selected compiler and SDK:

```sh
xcrun --find clang++
xcrun --show-sdk-path
```

Install CMake 3.22+ and ensure `cmake` and `ctest` are in PATH. If Homebrew is
already available, `brew install cmake` is one option. For the official CMake.app
installer from https://cmake.org/download/, choose one supporting your macOS,
install it in Applications, and in this Terminal run:

```sh
export PATH="/Applications/CMake.app/Contents/bin:$PATH"
cmake --version
ctest --version
python3 --version
```

Homebrew is not needed on a destination Mac that only installs the final PKG.
The script also uses Python 3, normally supplied by current Xcode tools.

## 3. Build and validate

Close Logic and all other audio hosts. In Terminal type `cd ` (including the
space), drag the extracted OpenMB-source-dev1 folder into Terminal and press
Return. Then run:

```sh
bash scripts/build_test_drop.sh 2>&1 | tee mac-build.log
```

Read the terminal output: the pipe above saves a log but can conceal a failing
script's exit status in some shells; success requires the final `Created unsigned
development DMG` message and manifest, not merely a zero status from tee.
For an exit status preserving invocation use `bash scripts/build_test_drop.sh`
directly instead.

The script fetches JUCE 7.0.12, builds the native AU and tests, checks the actual
binary's deployment target, and ad-hoc signs the AU. When prompted, type VALIDATE
only if you approve a temporary per-user AU copy for auval. The script removes
that copy on normal exit or failure. It refuses to replace an existing OpenMB.
A forced termination or power loss can leave the temporary AU behind; check
~/Library/Audio/Plug-Ins/Components/OpenMB.component before retrying.

If auval cannot discover the AU, stop and send the log for diagnosis. Do not skip
validation. Avoid running two copies of the build script concurrently.

## 4. Find and verify the output

On success the `dist` folder contains:

- OpenMB-v0.1.0-dev1-macOS-Monterey-arm64-UNSIGNED.dmg
- OpenMB-v0.1.0-dev1-macOS-Monterey-arm64-UNSIGNED-SHA256.txt
- AU validation log and JSON verification manifest

```sh
cd dist
shasum -a 256 -c OpenMB-v0.1.0-dev1-macOS-Monterey-arm64-UNSIGNED-SHA256.txt
open .
```

The DMG is mounted and checked by the build script. It contains Install OpenMB.pkg,
README.txt, Release Notes.txt and Uninstall OpenMB.command. There is no v1.0.0
release; development filenames deliberately reflect the incomplete feature set.

## 5. Install only when you choose to test

Prefer a disposable macOS test machine/volume. A separate user account does not
isolate the system-wide installation path. Installing this PKG explicitly writes
/Library/Audio/Plug-Ins/Components/OpenMB.component and requires admin approval.
Do not install over an existing OpenMB you need to preserve.

Double-click the DMG, read README.txt, then open Install OpenMB.pkg and follow the
standard Installer screens. This build is not Developer ID signed or notarized;
Gatekeeper may block it. Use Apple's per-item Privacy & Security approval only
if offered and you trust your locally built artifact. Do not disable Gatekeeper.
If policy prevents approval, stop: a signed/notarized distribution is needed.

After installation run:

```sh
auval -v aufx Omb1 Opmb
```

Open Logic's Plug-in Manager and check OpenMB validation. In a new test project,
insert OpenMB from the OpenMB manufacturer menu onto a mono or stereo track.
Play a duplicate audio file, compare bypassed/active output, and check for
crashes or dropouts. No parameter controls or useful preset/state tests exist
yet. Save/reopen the disposable project and report whether the plugin reloads.
Logic compatibility, installation, and uninstall remain unverified until tested.

## 6. Uninstall and report

Close audio hosts. Run Uninstall OpenMB.command from the mounted DMG, read the
prompt and type REMOVE only if you want that system-wide AU removed. It asks for
admin privileges only when the AU exists. No presets or unrelated files are
removed. Reopen Logic and confirm OpenMB is no longer available.

Send mac-build.log (review it for personal paths first), the auval output and
manifest, macOS/Xcode/Logic versions, and observations. Do not send signing
credentials. Failed builds are not a release; keep the actual error output.
