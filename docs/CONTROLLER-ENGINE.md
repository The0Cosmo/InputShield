# Controller engine and provider notes

## Current application functionality

The Controller Studio currently saves an editable mapping profile:
- Switch B/A/Y/X labels to Xbox A/B/X/Y labels;
- stick dead zone;
- sensitivity scalar;
- right-stick Y inversion;
- optional game executable path.

These settings are stored as local JSON. The current preview does not read live controller button/axis reports and does not emit a virtual gamepad. The UI explicitly marks virtual output as unavailable.

## Required architecture

A working Switch-to-Xbox path needs:
1. HID input enumeration and report reading for the physical controller (USB and Bluetooth tested separately).
2. Input normalization for buttons, triggers and sticks.
3. Mapping application and dead-zone/sensitivity processing.
4. A virtual gamepad provider that publishes a Windows device games can enumerate.
5. Disconnect handling, a global stop, duplicate-device warnings, rumble/output feedback support where available.
6. Tests with Windows Game Controller, Gamepad API, DirectInput and XInput games.

Changing button labels in a profile is not itself controller emulation.

## Provider evaluation

The project currently tracks LizardByte's `libvirtualhid` as a candidate:
- Its public library API describes generic HID, Xbox, DualShock, DualSense and Nintendo Switch Pro-style profiles.
- Windows uses a separate UMDF2/VHF driver package.
- The current Windows release package targets AMD64; Windows ARM64 release packages are not available in the reviewed documentation.
- The generated Windows driver package artifacts are under LizardByte Source-Available License 1.0. The product documentation also states that a machine license is required for driver-backed virtual devices.
- Its driver package is not a dependency that InputShield can silently bundle as MIT software.

Official references:
- https://github.com/LizardByte/libvirtualhid
- https://docs.lizardbyte.dev/projects/libvirtualhid/latest/md_docs_2windows-driver.html
- https://app.lizardbyte.dev/libvirtualhid/virtual-hid-driver/

ViGEmBus is an older alternative whose upstream project is archived/retired. It should not be treated as the actively maintained default.

## Safety requirements

- Never install a driver silently.
- Require a valid package signature and show publisher details before installation.
- Do not disable driver-signature enforcement or enable test-signing mode.
- Do not hide the physical controller until virtual output has been verified.
- Stop and destroy virtual devices cleanly on disconnect or application exit.
- Warn that anti-cheat compatibility is game-specific and not guaranteed.
- Keep the default profile editor useful without installing any third-party driver.

## Status

The device inventory and mapping profile editor are implemented in the preview. The HID report reader and virtual-device backend remain future development. No functional Switch-to-Xbox emulation is claimed yet.
