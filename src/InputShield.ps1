# InputShield - portable Windows input blocker (user-mode prototype)
# Requires Windows PowerShell 5.1 and Windows Forms (included with Windows).
# No administrator rights or third-party packages are required.

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$nativeSource = @'
using System;
using System.Runtime.InteropServices;

public sealed class InputShieldWindowItem
{
    public IntPtr Handle;
    public int ProcessId;
    public string ProcessName;
    public string WindowTitle;
    public string Display;

    public override string ToString() { return Display; }
}

public static class InputShieldNative
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WH_MOUSE_LL = 14;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    private const int VK_F12 = 0x7B;

    public static IntPtr TargetWindow = IntPtr.Zero;
    public static bool BlockKeyboard = false;
    public static bool BlockMouse = false;
    public static bool EmergencyPressed = false;
    public static string LastErrorMessage = "";

    private static IntPtr _keyboardHook = IntPtr.Zero;
    private static IntPtr _mouseHook = IntPtr.Zero;
    private static bool _armed = false;

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    private delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);

    // Keep delegate instances rooted for the lifetime of the hooks.
    private static LowLevelKeyboardProc _keyboardProc = KeyboardCallback;
    private static LowLevelMouseProc _mouseProc = MouseCallback;

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc callback, IntPtr module, uint threadId);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc callback, IntPtr module, uint threadId);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hook);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hook, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindow(IntPtr hwnd);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr GetModuleHandle(string moduleName);

    private static bool IsTargetForeground()
    {
        return TargetWindow != IntPtr.Zero && GetForegroundWindow() == TargetWindow;
    }

    private static IntPtr KeyboardCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && _armed && IsTargetForeground())
        {
            int message = wParam.ToInt32();
            KBDLLHOOKSTRUCT data = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));

            // F12 is a fail-safe: it is consumed and asks the UI to disable protection.
            if (data.vkCode == VK_F12 && (message == WM_KEYDOWN || message == WM_SYSKEYDOWN))
            {
                EmergencyPressed = true;
                return new IntPtr(1);
            }

            if (BlockKeyboard)
                return new IntPtr(1);
        }
        return CallNextHookEx(_keyboardHook, nCode, wParam, lParam);
    }

    private static IntPtr MouseCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && _armed && BlockMouse && IsTargetForeground())
            return new IntPtr(1);

        return CallNextHookEx(_mouseHook, nCode, wParam, lParam);
    }

    public static bool Install()
    {
        Uninstall();
        LastErrorMessage = "";
        EmergencyPressed = false;

        if (TargetWindow == IntPtr.Zero || !IsWindow(TargetWindow))
        {
            LastErrorMessage = "La finestra selezionata non è più disponibile. Aggiorna l'elenco.";
            return false;
        }
        if (!BlockKeyboard && !BlockMouse)
        {
            LastErrorMessage = "Seleziona almeno un tipo di input da bloccare.";
            return false;
        }

        IntPtr module = GetModuleHandle(null);

        // The keyboard hook is also used for the F12 emergency stop when only the mouse is blocked.
        _keyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, _keyboardProc, module, 0);
        if (_keyboardHook == IntPtr.Zero)
        {
            LastErrorMessage = "Impossibile attivare il filtro tastiera. Codice Windows: " + Marshal.GetLastWin32Error();
            Uninstall();
            return false;
        }

        if (BlockMouse)
        {
            _mouseHook = SetWindowsHookEx(WH_MOUSE_LL, _mouseProc, module, 0);
            if (_mouseHook == IntPtr.Zero)
            {
                LastErrorMessage = "Impossibile attivare il filtro mouse. Codice Windows: " + Marshal.GetLastWin32Error();
                Uninstall();
                return false;
            }
        }

        _armed = true;
        return true;
    }

    public static void Uninstall()
    {
        _armed = false;
        if (_mouseHook != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_mouseHook);
            _mouseHook = IntPtr.Zero;
        }
        if (_keyboardHook != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_keyboardHook);
            _keyboardHook = IntPtr.Zero;
        }
    }
}
'@

Add-Type -TypeDefinition $nativeSource -Language CSharp

function Get-VisibleWindows {
    $currentId = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $results = @()
    foreach ($p in [System.Diagnostics.Process]::GetProcesses()) {
        try {
            if ($p.Id -eq $currentId) { continue }
            $hwnd = $p.MainWindowHandle
            $title = $p.MainWindowTitle
            if ($hwnd -eq [IntPtr]::Zero -or [string]::IsNullOrWhiteSpace($title)) { continue }

            $entry = New-Object InputShieldWindowItem
            $entry.Handle = $hwnd
            $entry.ProcessId = $p.Id
            $entry.ProcessName = $p.ProcessName
            $entry.WindowTitle = $title
            $entry.Display = "{0}  —  {1}.exe  (PID {2})" -f $title, $p.ProcessName, $p.Id
            $results += $entry
        } catch {
            # Some protected/system processes cannot expose their window details.
        }
    }
    return @($results | Sort-Object Display)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'InputShield - blocco input'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(690, 535)
$form.MinimumSize = $form.Size
$form.MaximumSize = $form.Size
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.BackColor = [System.Drawing.Color]::FromArgb(247, 248, 250)

$header = New-Object System.Windows.Forms.Label
$header.Text = 'INPUTSHIELD'
$header.Font = New-Object System.Drawing.Font('Segoe UI', 19, [System.Drawing.FontStyle]::Bold)
$header.Location = New-Object System.Drawing.Point(22, 16)
$header.Size = New-Object System.Drawing.Size(620, 34)
$form.Controls.Add($header)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Scegli una finestra e blocca mouse e/o tastiera mentre è attiva.'
$subtitle.Location = New-Object System.Drawing.Point(24, 52)
$subtitle.Size = New-Object System.Drawing.Size(625, 22)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(75, 85, 99)
$form.Controls.Add($subtitle)

$groupTarget = New-Object System.Windows.Forms.GroupBox
$groupTarget.Text = '1. Attività / finestra da proteggere'
$groupTarget.Location = New-Object System.Drawing.Point(20, 86)
$groupTarget.Size = New-Object System.Drawing.Size(635, 105)
$form.Controls.Add($groupTarget)

$combo = New-Object System.Windows.Forms.ComboBox
$combo.Location = New-Object System.Drawing.Point(15, 29)
$combo.Size = New-Object System.Drawing.Size(485, 27)
$combo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$groupTarget.Controls.Add($combo)

$refresh = New-Object System.Windows.Forms.Button
$refresh.Text = 'Aggiorna'
$refresh.Location = New-Object System.Drawing.Point(510, 27)
$refresh.Size = New-Object System.Drawing.Size(108, 30)
$groupTarget.Controls.Add($refresh)

$targetHint = New-Object System.Windows.Forms.Label
$targetHint.Text = 'Seleziona la finestra esatta, non solo il nome del programma.'
$targetHint.Location = New-Object System.Drawing.Point(17, 66)
$targetHint.Size = New-Object System.Drawing.Size(590, 20)
$targetHint.ForeColor = [System.Drawing.Color]::FromArgb(90, 98, 110)
$groupTarget.Controls.Add($targetHint)

$groupInputs = New-Object System.Windows.Forms.GroupBox
$groupInputs.Text = '2. Input da bloccare quando la finestra è in primo piano'
$groupInputs.Location = New-Object System.Drawing.Point(20, 202)
$groupInputs.Size = New-Object System.Drawing.Size(635, 102)
$form.Controls.Add($groupInputs)

$checkKeyboard = New-Object System.Windows.Forms.CheckBox
$checkKeyboard.Text = 'Blocca tastiera'
$checkKeyboard.Location = New-Object System.Drawing.Point(18, 29)
$checkKeyboard.Size = New-Object System.Drawing.Size(180, 25)
$groupInputs.Controls.Add($checkKeyboard)

$checkMouse = New-Object System.Windows.Forms.CheckBox
$checkMouse.Text = 'Blocca mouse (movimento, clic e rotella)'
$checkMouse.Location = New-Object System.Drawing.Point(220, 29)
$checkMouse.Size = New-Object System.Drawing.Size(380, 25)
$groupInputs.Controls.Add($checkMouse)

$inputHint = New-Object System.Windows.Forms.Label
$inputHint.Text = 'Gli input restano disponibili nelle altre finestre. F12 disattiva immediatamente la protezione.'
$inputHint.Location = New-Object System.Drawing.Point(18, 63)
$inputHint.Size = New-Object System.Drawing.Size(595, 22)
$inputHint.ForeColor = [System.Drawing.Color]::FromArgb(90, 98, 110)
$groupInputs.Controls.Add($inputHint)

$groupControl = New-Object System.Windows.Forms.GroupBox
$groupControl.Text = '3. Controllo'
$groupControl.Location = New-Object System.Drawing.Point(20, 315)
$groupControl.Size = New-Object System.Drawing.Size(635, 94)
$form.Controls.Add($groupControl)

$start = New-Object System.Windows.Forms.Button
$start.Text = 'AVVIA BLOCCO'
$start.Location = New-Object System.Drawing.Point(18, 30)
$start.Size = New-Object System.Drawing.Size(175, 38)
$start.BackColor = [System.Drawing.Color]::FromArgb(22, 120, 72)
$start.ForeColor = [System.Drawing.Color]::White
$start.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$groupControl.Controls.Add($start)

$stop = New-Object System.Windows.Forms.Button
$stop.Text = 'DISATTIVA'
$stop.Location = New-Object System.Drawing.Point(205, 30)
$stop.Size = New-Object System.Drawing.Size(135, 38)
$stop.Enabled = $false
$groupControl.Controls.Add($stop)

$stopHint = New-Object System.Windows.Forms.Label
$stopHint.Text = 'Tasto di emergenza: F12'
$stopHint.Location = New-Object System.Drawing.Point(360, 39)
$stopHint.Size = New-Object System.Drawing.Size(240, 22)
$stopHint.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$groupControl.Controls.Add($stopHint)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Stato: disattivato'
$status.Location = New-Object System.Drawing.Point(24, 423)
$status.Size = New-Object System.Drawing.Size(620, 24)
$status.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$status.ForeColor = [System.Drawing.Color]::FromArgb(55, 65, 81)
$form.Controls.Add($status)

$warning = New-Object System.Windows.Forms.Label
$warning.Text = 'Nota: il blocco vale solo quando la finestra selezionata è in primo piano. Non isola da solo il Raw Input ricevuto da una seconda istanza in background.'
$warning.Location = New-Object System.Drawing.Point(24, 451)
$warning.Size = New-Object System.Drawing.Size(625, 42)
$warning.ForeColor = [System.Drawing.Color]::FromArgb(150, 75, 20)
$form.Controls.Add($warning)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 150

function Refresh-WindowList {
    $selectedText = $null
    if ($combo.SelectedItem) { $selectedText = $combo.SelectedItem.Display }
    $combo.Items.Clear()
    foreach ($w in (Get-VisibleWindows)) { [void]$combo.Items.Add($w) }
    if ($combo.Items.Count -gt 0) {
        $matchIndex = -1
        if ($selectedText) {
            for ($i = 0; $i -lt $combo.Items.Count; $i++) {
                if ($combo.Items[$i].Display -eq $selectedText) { $matchIndex = $i; break }
            }
        }
        if ($matchIndex -ge 0) { $combo.SelectedIndex = $matchIndex } else { $combo.SelectedIndex = 0 }
    }
}

function Stop-Protection([string]$reason = 'disattivato') {
    [InputShieldNative]::Uninstall()
    $timer.Stop()
    $start.Enabled = $true
    $stop.Enabled = $false
    $combo.Enabled = $true
    $refresh.Enabled = $true
    $checkKeyboard.Enabled = $true
    $checkMouse.Enabled = $true
    $status.Text = 'Stato: ' + $reason
    $status.ForeColor = [System.Drawing.Color]::FromArgb(55, 65, 81)
}

$refresh.Add_Click({ Refresh-WindowList })

$start.Add_Click({
    if (-not $combo.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show('Seleziona prima una finestra.', 'InputShield', 'OK', 'Warning') | Out-Null
        return
    }
    if (-not $checkKeyboard.Checked -and -not $checkMouse.Checked) {
        [System.Windows.Forms.MessageBox]::Show('Seleziona almeno Tastiera o Mouse.', 'InputShield', 'OK', 'Warning') | Out-Null
        return
    }

    $item = [InputShieldWindowItem]$combo.SelectedItem
    [InputShieldNative]::TargetWindow = $item.Handle
    [InputShieldNative]::BlockKeyboard = $checkKeyboard.Checked
    [InputShieldNative]::BlockMouse = $checkMouse.Checked

    if (-not [InputShieldNative]::Install()) {
        [System.Windows.Forms.MessageBox]::Show([InputShieldNative]::LastErrorMessage, 'InputShield - errore', 'OK', 'Error') | Out-Null
        return
    }

    $start.Enabled = $false
    $stop.Enabled = $true
    $combo.Enabled = $false
    $refresh.Enabled = $false
    $checkKeyboard.Enabled = $false
    $checkMouse.Enabled = $false
    $status.Text = 'PROTEZIONE ATTIVA: ' + $item.WindowTitle
    $status.ForeColor = [System.Drawing.Color]::FromArgb(22, 120, 72)
    $timer.Start()
})

$stop.Add_Click({ Stop-Protection 'disattivato manualmente' })

$timer.Add_Tick({
    if ([InputShieldNative]::EmergencyPressed) {
        Stop-Protection 'disattivato con F12 (emergenza)'
        [System.Windows.Forms.MessageBox]::Show('Protezione disattivata. Tastiera e mouse sono nuovamente disponibili.', 'InputShield', 'OK', 'Information') | Out-Null
        return
    }
    if (-not [InputShieldNative]::IsWindow([InputShieldNative]::TargetWindow)) {
        Stop-Protection 'finestra chiusa; protezione rimossa'
        return
    }
})

$form.Add_FormClosing({ [InputShieldNative]::Uninstall(); $timer.Stop() })
$form.Add_Shown({ Refresh-WindowList })

[System.Windows.Forms.Application]::EnableVisualStyles()
[void][System.Windows.Forms.Application]::Run($form)