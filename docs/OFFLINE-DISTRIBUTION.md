# Offline distribution and installation

## Application package

The current build provides a PowerShell 5.1/WPF application and a per-user installer. The UI runtime uses Windows components; it does not need separate .NET or VC++ redistributables on the supported Windows target.

Create the ZIP on a Windows PC:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Build-Offline-Package.ps1
```

Output:
- `release\InputShield-0.3.0-preview-Windows-x64-Offline.zip`
- `release\InputShield-0.3.0-preview-Windows-x64-Offline.zip.sha256`

On the offline computer, extract the ZIP and run `Install-InputShield.cmd`. The installer copies the application to `%LOCALAPPDATA%\Programs\InputShield`, creates Start Menu shortcuts and needs no administrator rights. Profiles and logs are stored in `%LOCALAPPDATA%\InputShield`, separate from application files. Uninstalling preserves user data by default.

## Optional virtual HID driver

The default ZIP deliberately excludes third-party driver binaries. The official LizardByte Windows driver package is separately licensed; the Windows driver artifacts use the LizardByte Source-Available License 1.0 and machine licensing is required for driver-backed virtual devices. See the official project and product documentation before obtaining or including it.

For a personal offline package only, the user may place an officially obtained MSI at `packages\optional\libvirtualhid-Windows-AMD64-driver-installer.msi` and pass `-IncludeUserSuppliedVirtualHidMsi` to the build script. The script requires a valid Authenticode signature and copies it into that private ZIP. The optional launch script displays the signer and requires explicit confirmation before invoking the MSI with UAC.

Do not redistribute the driver MSI unless its license and purchase terms explicitly authorize it. The current InputShield preview does not yet integrate the libvirtualhid API, so installing the driver alone does not create a virtual Xbox gamepad in InputShield.

## Release validation required

Before calling this a production installer, test on clean, disconnected Windows 11 x64 systems:
- application install, launch and uninstall;
- profile create, save, import, export and delete;
- log/report export;
- reconnecting and disconnecting controllers;
- MSI signature verification and provider license activation (if used);
- app updates and rollback;
- accessibility, scaling and high-DPI display.

This repository's current installer is a per-user PowerShell installer, not a signed MSI or EXE installer.
