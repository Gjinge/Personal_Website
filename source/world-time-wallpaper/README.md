# World Time Wallpaper — website source snapshot

This folder preserves the local project source used for the [portfolio page](../../projects/world-time-wallpaper/). The [original repository](https://github.com/Sudaweiye/world-time-wallpaper) contains an earlier public version.

- `rainmeter/WorldTimeOverlay/WorldTimeOverlay.ini`: ten clock measures and display meters.
- `scripts/generate_timezone_wallpaper.py`: generates the clean wallpaper and a static preview with Pillow, using NASA Earth city-lights imagery from Wikimedia Commons.
- `scripts/install_rainmeter_overlay.ps1`: runs the installer.
- `scripts/ensure_world_time_overlay.ps1`: installs the skin, updates Rainmeter, and can create the Windows startup shortcut.
- `scripts/watch_world_time_overlay.ps1`: checks the installation every five minutes while signed in.

The [clean wallpaper](../../assets/img/world-time/cover.png) and [static preview](../../assets/img/world-time/static-preview.png) are stored with the website images. The Rainmeter skin uses fixed UTC offsets; daylight saving changes require updating offsets for affected cities. See [LICENSE](LICENSE) for the source license. Earth image credit: [NASA via Wikimedia Commons](https://commons.wikimedia.org/wiki/Special:FilePath/City_Lights_2012_-_Flat_map.jpg).
