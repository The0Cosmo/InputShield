# Controller engine: design and safety notes

## Goal

InputShield is intended to support a physical controller (for example, Nintendo Switch Pro Controller over USB or Bluetooth) as an input source and optionally expose a remapped virtual Xbox-compatible controller to games.

The desired pipeline is:

1. Discover physical HID/game-controller devices and show their connection state.
2. Read supported controller reports without claiming exclusive access by default.
3. Apply a user-editable mapping (buttons, triggers, sticks, dead zones, sensitivity, inversion).
4. Send the mapped state to a virtual gamepad provider.
5. Let the user test buttons and axes, save per-game profiles, and stop output immediately.

## Important distinction

Changing button labels in the UI is not enough to make a game see an Xbox controller. The final step requires a virtual-device provider/driver that Windows and games can enumerate. This is a separate system component, may require administrator approval, and must be installed and tested independently of the InputShield UI.

## Driver/provider evaluation

- **ViGEmBus**: supports Xbox 360 and DualShock 4 emulation, but its upstream repository is archived/retired. Do not silently bundle it as if it were actively maintained. See https://github.com/nefarius/ViGEmBus.
- **libvirtualhid / Virtual HID Driver (LizardByte)**: a newer option described by its authors for virtual gamepads, including Xbox and Nintendo Switch-style devices. The Windows driver is distributed separately and has its own source-available licensing terms. Review the exact license, redistribution terms, signing status, supported Windows versions, and installation flow before bundling anything. See https://app.lizardbyte.dev/2026-08-16-introducing-libvirtualhid-and-virtual-hid-driver/.

InputShield must not download drivers at runtime. Offline packages must contain only components whose redistribution is explicitly permitted, with their original notices and hashes.

## Safety requirements

- Never install a driver silently.
- Show the provider name, publisher/signature status, version, architecture, and license before installation.
- Require explicit user confirmation before launching a driver installer.
- Do not disable Windows driver-signature enforcement or enable test-signing mode.
- Provide a visible stop control and a global emergency stop.
- Avoid hiding the physical controller until virtual output has been verified.
- Detect and warn about duplicate physical + virtual inputs that can cause double input.
- Do not promise anti-cheat compatibility; some games may reject virtual devices.

## Implementation status

This document describes the target architecture, not completed functionality. The current PowerShell prototype does not read controller reports and does not create virtual controllers. No Switch-to-Xbox conversion is currently implemented.
