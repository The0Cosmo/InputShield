# InputShield

InputShield is an independent Windows input-management desktop project. Its focus is device diagnostics, local per-game profiles, controller mapping presets, and carefully scoped input controls.

> **Version 0.3 preview.** The application and per-user installer are available for testing. It is not yet a production-ready virtual controller mapper or a per-process input-isolation solution.

## Included features

- Modern WPF desktop interface for Windows PowerShell 5.1.
- Windows Plug and Play input-device inventory.
- Controller studio with editable Switch-label to Xbox-label mapping presets.
- Stick dead-zone, sensitivity and Y-axis inversion values saved in profiles.
- Local game profiles with optional EXE path.
- Profile import/export as JSON.
- Local activity logs and exportable Windows diagnostic report.
- Legacy keyboard/mouse foreground-only prototype with F12 emergency stop.
- Per-user installer and uninstaller; no admin rights required for the application itself.
- Offline ZIP builder with SHA-256 checksum output.

## Quick start

From a cloned repository or extracted source ZIP:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\InputShield.App.ps1
```

Or double-click `Launch-InputShield.cmd` to run the application directly.

## Offline installation package

Run this on a Windows PC with PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Build-Offline-Package.ps1
```

This creates `release\InputShield-0.3.0-preview-Windows-x64-Offline.zip` and a matching `.sha256` file. Copy the ZIP to the offline PC, extract it, then double-click `Install-InputShield.cmd`. The app is installed under the current user's LocalAppData and a Start Menu shortcut is created. No administrator rights or network access are needed for the app installation.

The UI uses Windows PowerShell 5.1 and WPF already supplied by supported Windows installations; there are no third-party app runtime packages to download.

## Optional virtual-controller driver

No third-party driver is included by default. LizardByte's libvirtualhid has a separate Windows driver package and a separate licensing model. Its current published Windows driver targets AMD64, and the generated Windows driver package artifacts are under the LizardByte Source-Available License. A machine license is required for driver-backed virtual devices.

For a private offline bundle only, obtain the driver through the official channel and check its current license and purchase terms. Place the official MSI at `packages\optional\libvirtualhid-Windows-AMD64-driver-installer.msi`, then build with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Build-Offline-Package.ps1 -IncludeUserSuppliedVirtualHidMsi
```

The build checks the MSI's Authenticode signature before copying it. Do not redistribute the optional MSI unless its license and your purchase terms explicitly allow it. `Install-Optional-VirtualHID.ps1` requires a valid signature and explicit confirmation, then launches the upstream MSI with UAC.

**Installing that driver alone does not enable virtual output in InputShield.** The present application does not yet call the libvirtualhid API or create a virtual gamepad.

Official upstream references:
- https://github.com/LizardByte/libvirtualhid
- https://app.lizardbyte.dev/libvirtualhid/virtual-hid-driver/

## Known limitations

- The mapping editor saves a profile only; it does not read live controller reports.
- No virtual Xbox controller is created yet.
- No per-process Raw Input, DirectInput, XInput or HID isolation is implemented.
- The legacy hook prototype blocks input only while the selected window is foreground.
- No anti-cheat compatibility is claimed.
- The app and installer scripts have not yet been validated on a clean Windows VM.

## Data location

Profiles and logs are stored in `%LOCALAPPDATA%\InputShield`. The uninstaller preserves this data by default.

## Automated validation

GitHub Actions parses all PowerShell scripts, loads the WPF window in a headless Windows PowerShell 5.1 process, checks the offline installer payload and builds the offline ZIP artifact on every push to `main`.

## Security and license

InputShield's own code is MIT-licensed. Third-party components retain their own licenses. See [SECURITY.md](SECURITY.md), [docs/CONTROLLER-ENGINE.md](docs/CONTROLLER-ENGINE.md), and [docs/OFFLINE-DISTRIBUTION.md](docs/OFFLINE-DISTRIBUTION.md).
