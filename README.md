# InputShield

InputShield is an experimental Windows PowerShell 5.1 user-mode input-blocking prototype.

## Current status

- Window picker for visible top-level windows
- Optional low-level keyboard and mouse hooks
- F12 emergency stop and manual disable
- No third-party runtime dependency; uses Windows PowerShell and Windows Forms

## Important limitations

This prototype only suppresses standard low-level keyboard/mouse events while the selected window is the foreground window. It does **not** isolate Raw Input, DirectInput, controller devices, or background game instances. It is therefore **not** a replacement for HidHide or Nucleus Co-op Proto Input and is not yet validated for the two-instance Minecraft use case.

It has not been packaged as a tested installer and has not been validated on the user's PC. Run only after reviewing the source; use a test environment first.

## Run from source

Open Windows PowerShell 5.1 and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\InputShield.ps1
```

F12 is the emergency stop while the selected target window is in the foreground.

## Roadmap

- Proper installed application and uninstaller
- Build/test pipeline on supported Windows versions
- Per-process/device routing and Raw Input investigation
- Signed driver/service only if technically necessary and properly reviewed
