# InputShield — implementation plan and offline requirements

Last reviewed: 2026-11-25

## What is actually implemented

The current 0.3 preview is a Windows PowerShell/WPF prototype. It provides a GUI, local profiles/settings and device/process inventory. Its low-level keyboard/mouse hook is foreground-window scoped. It is **not** a per-process input isolation engine and it does not create a virtual Xbox controller.

Do not advertise the preview as delivering those two capabilities.

## Feature status

| Feature | Current status | What is still required |
|---|---|---|
| Offline installation of the current preview | Available, subject to validating the target PC and installer | Test on the target PC |
| GUI | Prototype available | UX/accessibility and target-PC testing |
| Per-game profiles | Local profile functionality available | Schema versioning and migration tests |
| Device inventory | Prototype available | Test device enumeration on target hardware |
| Switch Pro Controller -> Xbox 360/XInput | Not implemented in InputShield | HID input reader, mapping engine, virtual XInput device backend, signed/compatible driver package, licensing review and end-to-end tests |
| Live remapping | Not implemented as a complete physical-to-virtual pipeline | Input capture, mapping pipeline, dead-zone/axis calibration, hot-plug, feedback and latency tests |
| Per-game keyboard/mouse isolation | Not implemented | Supported OS-level routing/virtualization architecture; low-level hooks alone cannot reliably isolate Raw Input, DirectInput or background-window input |

## Controller architecture required

A real Switch Pro -> Xbox implementation needs a pipeline:

1. Discover and open the physical controller using a supported HID API.
2. Read and decode reports, including buttons, triggers, sticks and connection state.
3. Apply configurable mappings, axis inversion, dead zones and calibration.
4. Send the resulting state to a virtual Xbox/XInput device backend.
5. Handle disconnect/reconnect, rumble/LED capabilities where supported, and clean shutdown.
6. Verify that games see the virtual device and do not also consume the physical device (avoid duplicate input).

A virtual XInput device is not something a normal PowerShell/WPF application can create by itself. It requires a compatible virtual-device driver/backend. Driver installation normally requires administrator approval, and the driver must be correctly signed for the target Windows security configuration. Do not disable driver-signature enforcement or Windows security features to force installation.

## Keyboard and mouse isolation architecture required

A foreground low-level hook can suppress some input while a selected window is active, but it cannot guarantee isolation from background game input paths such as Raw Input, DirectInput or device-specific HID access. Reliable per-game isolation needs a separately validated OS/device-routing design and explicit compatibility testing with the target games. Never claim process isolation based only on a foreground hook.

## Offline deployment checklist

Prepare on the internet-connected staging PC, then transfer to the offline target PC:

- InputShield release archive and source archive.
- SHA-256 manifest for every downloaded artifact.
- Exact driver/backend installer, version, publisher and license, only after the backend is selected.
- Vendor documentation and license text.
- Any required Microsoft runtime installers, if the chosen compiled backend actually needs them.
- Installer, uninstaller, configuration defaults and recovery instructions.
- A manifest containing file name, version, source URL, SHA-256, signature status and license.
- A target-PC test plan and rollback procedure.

Do not bundle third-party drivers without checking redistribution rights, signing status, supported Windows versions and silent/offline installation terms. An offline package can carry a driver installer, but cannot bypass admin approval, driver signing, hardware compatibility or any first-use licensing/activation requirement.

## Release gate

A release must not be called complete until all of these pass on the actual offline target PC:

- Clean installation and uninstall with network physically disconnected.
- Driver signature and publisher verification (if a driver is used).
- Switch Pro controller USB and Bluetooth discovery.
- Correct button/axis mapping in an XInput test application and at least one target game.
- Reconnect, sleep/resume, multiple-controller and duplicate-device tests.
- Keyboard/mouse isolation tests with two game instances, including Raw Input and background-window behavior.
- No unexpected input leakage to the other instance.
- Logs and recovery path verified.

## Current honest release statement

InputShield 0.3 preview is an offline-capable GUI/profile prototype, not yet a complete controller emulator or per-process keyboard/mouse isolation product. The advanced functions require engineering, a driver/backend decision, and validation on the actual target PC.