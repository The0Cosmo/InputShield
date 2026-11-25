# Offline distribution and installation

## Distribution goal

Provide one downloadable offline bundle for supported Windows PCs. The bundle should include the InputShield application, documentation, license notices, checksums, and any approved runtime files. The application must not need an internet connection after installation.

## Two installation layers

### 1. InputShield application

The application installer should:
- install per-user by default (no administrator rights);
- create and remove a Start Menu shortcut;
- keep profiles and settings under the current user's local application-data folder;
- include all application runtime dependencies;
- offer an uninstall action;
- never fetch components from the internet.

### 2. Optional virtual-controller provider

Virtual gamepad output is not part of the ordinary UI installation. If a provider is selected and its redistribution terms permit inclusion:
- ship its official installer and original license/third-party notices;
- verify its SHA-256 before offering installation;
- explain that a driver installation may require administrator approval and a Windows restart;
- require explicit confirmation and let the provider's signed installer perform the installation.

If no provider is installed, InputShield may still offer device discovery, diagnostics, profile editing, and mapping previews, but it must clearly label virtual Xbox output as unavailable.

## Offline build workflow

The release pipeline should produce architecture-specific packages (initial target: Windows 10/11 x64), generate SHA-256 checksums, and test installation on a clean Windows VM with networking disabled. Do not label a package production-ready until clean-machine installation, uninstall, upgrade, device-disconnect, and emergency-stop tests pass.

## Current status

The repository currently contains a PowerShell 5.1 prototype, not a compiled installer. This document is a packaging specification and does not claim that an offline installer has already been built or tested.
