# InputShield

InputShield is an independent Windows input-management project. The goal is a polished desktop application for input-device diagnostics, per-game profiles, keyboard/mouse controls, and controller remapping.

> **Current status: experimental prototype.** The repository is public, but the current executable source is not a production-ready input-isolation engine and no finished offline installer has been released.

## Product goals

- A modern Windows desktop interface with a dashboard, sidebar navigation, light/dark themes, device cards, profiles, diagnostics, and activity logs.
- Keyboard/mouse controls and clearly scoped per-window/process input experiments.
- Controller discovery and live diagnostics for supported gamepads.
- Editable controller mappings, including Nintendo Switch Pro Controller to virtual Xbox-compatible output.
- Per-game profiles, dead-zone/sensitivity settings, button testing, and emergency stop.
- Offline-first distribution: one self-contained application bundle with checksums and no runtime downloads.

## What works in the current prototype

A first modern WPF desktop UI shell is available in `src/InputShield.Modern.ps1`, launched with `Launch-InputShield.cmd`. It includes navigation, dashboard cards, a Windows Plug and Play device inventory scan, and a controller-mapping preview. The profile, keyboard/mouse, and settings sections are placeholders; the mapping preview is illustrative and does not yet emit a virtual controller.

The original PowerShell 5.1 input-hook prototype remains available in `src/InputShield.ps1`:
- lists visible top-level windows;
- installs low-level Windows keyboard/mouse hooks;
- suppresses selected input events only while the chosen window is in the foreground;
- provides F12 emergency stop and removes hooks when the UI closes.

Run it with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\InputShield.ps1
```

## What does not work yet

The current prototype does **not** isolate Raw Input, DirectInput, XInput, HID, or background-game input. It does not read Switch controller reports and does not create a virtual Xbox controller. The Switch-to-Xbox feature is a development target, not an available feature.

A virtual Xbox controller requires a separate virtual-device provider/driver. That component has its own licensing, signing, Windows compatibility, and installation requirements. InputShield will not silently install drivers, disable driver-signature enforcement, or claim compatibility that has not been tested.

See:
- [Controller engine design and driver evaluation](docs/CONTROLLER-ENGINE.md)
- [Offline distribution and installation plan](docs/OFFLINE-DISTRIBUTION.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)

## Development priorities

1. Replace the prototype UI with the modern desktop interface.
2. Build a reliable controller discovery and diagnostics layer.
3. Implement mapping and virtual-device output using a reviewed, legally redistributable provider.
4. Redesign keyboard/mouse isolation around tested Windows input-routing behavior.
5. Build and test the offline installer on clean Windows 10/11 x64 systems.

## License

MIT for InputShield's own code. Third-party components retain their own licenses and notices.
