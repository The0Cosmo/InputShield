# InputShield

InputShield is an experimental Windows input-blocking utility written in PowerShell/C#.

> **Status: prototype — not production-ready.** Do not rely on it for security, accessibility-critical use, or isolation of background applications.

## Current implementation

- Lists visible top-level windows.
- Installs low-level Windows keyboard/mouse hooks.
- Suppresses selected input events only while the chosen window is the foreground window.
- F12 emergency stop; manual stop; hooks are removed when the UI closes.

## Critical limitations

This implementation does **not** provide per-process input routing. It does not intercept or isolate Raw Input, DirectInput, XInput, HID, or controller devices. It cannot guarantee that a background game instance will not receive mouse/keyboard input. It is not a replacement for HidHide, Nucleus Co-op Proto Input, or a properly engineered virtual-device/driver solution.

The current source has not completed Windows compatibility, reliability, accessibility, or security testing. No signed driver or production installer is provided. Use only on a test machine and review the code before running it.

## Run the prototype

Requires Windows PowerShell 5.1 and Windows Forms (included with Windows):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\src\InputShield.ps1
```

F12 is the emergency stop while the selected target window is in the foreground. Closing the application also removes the hooks.

## Development roadmap

1. Define and test the supported input-isolation scenarios.
2. Prototype device/process routing and evaluate Windows Raw Input behavior.
3. Add automated Windows tests and repeatable packaging.
4. Conduct security and accessibility review.
5. Sign and publish a production installer only after validation.

## Contributing

Bug reports and reproducible test cases are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).
