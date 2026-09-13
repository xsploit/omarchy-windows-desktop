# Verification

Packaging checks on 2026-09-12:

- Staged install into an empty temporary home, while preserving an existing monitor file.
- Rollback restored an overwritten input file and removed files introduced by the install.
- Python launcher syntax, shell launcher syntax, JSON parsing and Omarchy plugin manifest validation.
- Targeted credential/contact scan and allowlist inspection. No runtime app index, cookies, browser profiles, recordings, account exports or build binaries are tracked.
- Native Aero Snap geometry tests compiled and passed against the packaged sources.
- Packaged native plugin sources and Qt HDR panel compiled against installed Hyprland 0.56.2/Qt6.
- All three built plugins passed three load/unload cycles each in an isolated nested compositor. The initial harness used a runtime socket path longer than the UNIX socket limit; shortening it resolved the harness failure.

Run:

```sh
python3 tests/test_install.py
make -C native/aero-snap test BUILD_DIR=../../build
# After building the plugins (install.py --apply --build-native to a staging home):
python3 tests/native_smoke.py
```

The native smoke test launches a temporary nested compositor and cycles each plugin through load/unload three times. It does not load plugins into the host desktop. Successful loading is ABI/smoke evidence, not complete UI validation.

Earlier live checks on the source machine included overlapping-window pointer clicks, maximized/floating transitions, stale focus notifications, keeping minimized windows minimized, unchanged cursor coordinates on focus changes, Chrome external-link activation, and taskbar restoration. The microphone-quality investigation did not establish a fix. A clean-machine installation and every possible application's title-bar behavior have not been verified.
