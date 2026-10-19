# Validation status

Current Linux x86_64 instance: GCC 14.2, CMake 4.4.4, Debug build with AddressSanitizer and UndefinedBehaviorSanitizer. CTest: 1/1 test executable passed; it exercises six static curves, soft-knee continuity, range bounds, envelope settling at 44.1/48/88.2/96/176.4/192 kHz, reset, and nonfinite detector handling.

Not yet verified: JUCE plugin compilation, AU validation, Logic behavior, allocation instrumentation, audio quality, performance, GUI, state/automation, multiband and phase engines, packaging, installation or uninstall. No DMG or production release exists.
