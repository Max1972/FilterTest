# Implementation milestones

1. CMake and portable core compile; JUCE skeleton written; native AU build pending.
2. Initial dynamics curves/envelope tested; parameter smoothing, detector options and deeper audio regression tests pending.
3. Six independent overlapping frequency bands pending.
4. Minimum Phase engine pending.
5. Linear Phase engine pending.
6. Distinct Dynamic Phase engine, comparative measurements and technical report pending.
7. Stereo/Mid-Side/external sidechain pending.
8. Interactive spectrum GUI pending.
9. Presets, automation, state, A/B, undo and Logic validation pending.
10. Real-time instrumentation, optimization and audio regression pending.
11. Native PKG installer pending.
12. DMG generation, signing when configured, isolated install/uninstall tests and release verification pending.

Mac checkpoint: build the AU skeleton before investing in the full interface. Keep Monterey 12.0 and arm64 explicit. Do not call source-only or Linux-only results a release.
