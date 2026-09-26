# Verification

Checks on 2026-09-26 (source machine, Omarchy 4.0.4):

- QML parsing (Qt 6 `qmlformat`) and a runtime load of every changed Quickshell flyout (Wi-Fi, Bluetooth, sound, quick settings, widgets, Start); each loaded without warnings or errors.
- Settings launched through `omarchy-win11-settings`, reported live text scale, terminal size and HDR state over IPC, switched sections on a second launch without spawning another instance, and logged no errors. Opening it changed no setting.
- `desktop-settings-control` unit tests with mocked commands: input validation, foot config validated before replacement, exact text-scale restore, HDR only on explicit request.
- Scan of the published files for home paths, e-mail addresses, credentials, network names and IP addresses.
- Not verified: pointer-driven clicks, hover-preview behaviour under heavy window churn, a real Wi-Fi password connection, and a clean-machine install.


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
