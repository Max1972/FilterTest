# Building

Portable checks (CMake 3.22+, C++17 compiler):

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug -DOPENMB_SANITIZE=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

On the M1 Pro install compatible Xcode/command line tools and CMake, then:

```sh
cmake -S . -B build-mac -DCMAKE_BUILD_TYPE=Release -DOPENMB_BUILD_PLUGIN=ON -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0
cmake --build build-mac --parallel 4
ctest --test-dir build-mac --output-on-failure
```

JUCE 7.0.12 is fetched from GitHub. The AU and Standalone targets are enabled on macOS. This skeleton has fixed full-band compression and no exposed parameters yet. Do not use it for production. AU compilation and validation must be checked on a Mac before claiming the first milestone complete. Installation is deliberately not automatic.
