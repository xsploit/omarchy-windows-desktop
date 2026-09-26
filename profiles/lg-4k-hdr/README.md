# Optional LG 4K TV profile

Original hardware: HDMI-A-1, 3840×2160 at 60 Hz, scale 1.75, 10-bit HDR, SDR white at 203 nits so browsers and native windows share one brightness. **Do not apply this to an arbitrary monitor.** Normal installation preserves your existing monitor file.

Opt in with `python3 install.py --apply --build-native --with-lg-hdr`. The source-built HDR panel requires Qt6Widgets and the shader validator requires `glslang`. HDR starts without the software exposure boost; after logging in:

```sh
hdr-brightness-control set 0
hdr-brightness
```

Set a comfortable level yourself. The captured user's final level was 86 (5.3× signal exposure); that is recorded for recreation, not applied by default. 100 means 6× signal exposure, not Windows' brightness scale or a measured panel maximum. Bright highlights may clip/flatten. The helper checks HDMI-A-1 is actually using HDR and refreshes its runtime monitor ID at login.

The included monitor file configures this TV. To use a different output, adapt both `monitors.lua` and the output lookup in `hdr-brightness-control`. This does not use DDC or change the TV's own settings.
