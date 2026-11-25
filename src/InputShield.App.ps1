# InputShield Desktop App - PowerShell 5.1 / WPF
# Real features: device/process inventory, local profiles, editable mapping presets,
# diagnostics export and logs. Virtual Xbox output and per-process Raw Input routing
# are NOT implemented; the UI states this explicitly.
$ErrorActionPreference='Stop'
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $arguments='-NoProfile -ExecutionPolicy Bypass -STA -File "'+$PSCommandPath+'"'
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments
    exit
}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$script:AppRoot=Join-Path $env:LOCALAPPDATA 'InputShield'
$script:ProfileRoot=Join-Path $script:AppRoot 'Profiles'
$script:LogRoot=Join-Path $script:AppRoot 'Logs'
$script:LogFile=Join-Path $script:LogRoot 'inputshield.log'
New-Item -ItemType Directory -Path $script:ProfileRoot,$script:LogRoot -Force | Out-Null
[xml]$xaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="InputShield" Width="1240" Height="790" MinWidth="1040" MinHeight="680" WindowStartupLocation="CenterScreen" Background="#F2F6F3" FontFamily="Segoe UI">
<Window.Resources>
 <Style TargetType="Button"><Setter Property="Padding" Value="13,9"/><Setter Property="Margin" Value="0,3,0,3"/><Setter Property="Background" Value="#DDF3E4"/><Setter Property="Foreground" Value="#173526"/><Setter Property="BorderThickness" Value="0"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Cursor" Value="Hand"/></Style>
 <Style TargetType="TextBox"><Setter Property="Padding" Value="9,7"/><Setter Property="Margin" Value="0,4,0,8"/><Setter Property="BorderBrush" Value="#D8E2DB"/><Setter Property="BorderThickness" Value="1"/></Style>
 <Style TargetType="ComboBox"><Setter Property="Padding" Value="7,5"/><Setter Property="Margin" Value="0,4,0,8"/></Style>
</Window.Resources>
<Grid><Grid.ColumnDefinitions><ColumnDefinition Width="228"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
<Border x:Name="Sidebar" Grid.Column="0" Background="#17271F"><DockPanel Margin="17">
 <StackPanel DockPanel.Dock="Top" Margin="4,12,4,28"><TextBlock Text="◈ INPUTSHIELD" Foreground="#F0FFF4" FontSize="20" FontWeight="Bold"/><TextBlock Text="INPUT CONTROL CENTER" Foreground="#91CBA6" FontSize="9" Margin="2,6,0,0"/></StackPanel>
 <StackPanel DockPanel.Dock="Bottom" Margin="4,0,4,8"><Border Background="#294333" CornerRadius="10" Padding="12"><StackPanel><TextBlock Text="LOCAL & OFFLINE" Foreground="#A9E6BC" FontWeight="Bold" FontSize="10"/><TextBlock Text="Profiles stay on this PC" Foreground="White" Margin="0,5,0,0" FontSize="11"/></StackPanel></Border><TextBlock Text="InputShield 0.3 · Preview" Foreground="#8BA394" FontSize="10" Margin="2,12,0,0"/></StackPanel>
 <StackPanel>
  <Button x:Name="NavDashboard" Content="⌂   Overview" Background="#315C43" Foreground="White" HorizontalContentAlignment="Left"/>
  <Button x:Name="NavDevices" Content="▣   Devices" Background="#294333" Foreground="White" HorizontalContentAlignment="Left"/>
  <Button x:Name="NavController" Content="◉   Controller studio" Background="#294333" Foreground="White" HorizontalContentAlignment="Left"/>
  <Button x:Name="NavProfiles" Content="▤   Game profiles" Background="#294333" Foreground="White" HorizontalContentAlignment="Left"/>
  <Button x:Name="NavInput" Content="⌨   Keyboard &amp; mouse" Background="#294333" Foreground="White" HorizontalContentAlignment="Left"/>
  <Button x:Name="NavDiagnostics" Content="≡   Diagnostics &amp; logs" Background="#294333" Foreground="White" HorizontalContentAlignment="Left"/>
  <Button x:Name="NavSettings" Content="⚙   Settings" Background="#294333" Foreground="White" HorizontalContentAlignment="Left"/>
 </StackPanel>
</DockPanel></Border>
<Grid Grid.Column="1" Margin="28">
 <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
 <Grid Grid.Row="0" Margin="0,0,0,20">
  <StackPanel><TextBlock x:Name="PageTitle" Text="Overview" FontSize="29" FontWeight="Bold" Foreground="#19271F"/><TextBlock x:Name="PageSub" Text="Devices, controller profiles and diagnostics in one place." Foreground="#718078" Margin="0,5,0,0"/></StackPanel>
  <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center"><Border Background="#E2F4E7" CornerRadius="14" Padding="10,6" Margin="0,0,8,0"><TextBlock Text="● OFFLINE READY" Foreground="#28784D" FontSize="10" FontWeight="Bold"/></Border><Button x:Name="RefreshAll" Content="↻ Refresh" Padding="14,9"/></StackPanel>
 </Grid>
 <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto"><Grid>
  <Grid x:Name="PageDashboard">
   <Grid.RowDefinitions><RowDefinition Height="116"/><RowDefinition Height="16"/><RowDefinition Height="220"/><RowDefinition Height="16"/><RowDefinition Height="Auto"/></Grid.RowDefinitions><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
   <Border Grid.Row="0" Grid.Column="0" Background="White" CornerRadius="14" Padding="17" Margin="0,0,8,0"><StackPanel><TextBlock Text="INPUT DEVICES" Foreground="#718078" FontSize="10" FontWeight="Bold"/><TextBlock x:Name="CardDeviceCount" Text="—" FontSize="34" FontWeight="Bold" Margin="0,6,0,0"/><TextBlock Text="Detected by Windows" Foreground="#718078" FontSize="11"/></StackPanel></Border>
   <Border Grid.Row="0" Grid.Column="1" Background="White" CornerRadius="14" Padding="17" Margin="4,0"><StackPanel><TextBlock Text="SAVED PROFILES" Foreground="#718078" FontSize="10" FontWeight="Bold"/><TextBlock x:Name="CardProfileCount" Text="0" FontSize="34" FontWeight="Bold" Margin="0,6,0,0"/><TextBlock Text="Stored locally" Foreground="#718078" FontSize="11"/></StackPanel></Border>
   <Border Grid.Row="0" Grid.Column="2" Background="White" CornerRadius="14" Padding="17" Margin="8,0,0,0"><StackPanel><TextBlock Text="VIRTUAL XBOX OUTPUT" Foreground="#718078" FontSize="10" FontWeight="Bold"/><TextBlock Text="NOT CONNECTED" Foreground="#A56A20" FontSize="18" FontWeight="Bold" Margin="0,10,0,0"/><TextBlock Text="Driver/API integration pending" Foreground="#718078" FontSize="11"/></StackPanel></Border>
   <Border Grid.Row="2" Grid.ColumnSpan="2" Background="White" CornerRadius="14" Padding="20" Margin="0,0,8,0"><StackPanel><TextBlock Text="Controller studio" FontSize="18" FontWeight="Bold"/><TextBlock Text="Build a per-game layout for your controller. Switch button labels can be mapped to the Xbox layout and saved in profiles." Foreground="#718078" TextWrapping="Wrap" Margin="0,8,0,14"/><Border Background="#EFF8F1" CornerRadius="10" Padding="14"><StackPanel><TextBlock Text="SWITCH → XBOX MAPPING PRESET" Foreground="#28784D" FontSize="10" FontWeight="Bold"/><TextBlock Text="Switch B → Xbox A   ·   Switch A → Xbox B" FontSize="14" FontWeight="SemiBold" Margin="0,8,0,3"/><TextBlock Text="Switch Y → Xbox X   ·   Switch X → Xbox Y" FontSize="14" FontWeight="SemiBold"/><TextBlock Text="This saves a layout only; it does not yet create a virtual gamepad." Foreground="#718078" FontSize="11" Margin="0,8,0,0"/></StackPanel></Border><Button x:Name="QuickController" Content="Configure controller mapping →" HorizontalAlignment="Left" Margin="0,12,0,0"/></StackPanel></Border>
   <Border Grid.Row="2" Grid.Column="2" Background="#20392B" CornerRadius="14" Padding="18" Margin="8,0,0,0"><StackPanel><TextBlock Text="SAFETY" Foreground="#A9E6BC" FontWeight="Bold" FontSize="10"/><TextBlock Text="You stay in control." Foreground="White" FontSize="20" FontWeight="Bold" Margin="0,10,0,8"/><TextBlock Text="No silent driver installs, no anti-cheat bypass and no hidden background hooks." Foreground="#D5E9DB" TextWrapping="Wrap" FontSize="12"/><TextBlock Text="F12 emergency stop is available in the legacy foreground-only prototype." Foreground="#A9E6BC" TextWrapping="Wrap" FontSize="11" Margin="0,10,0,0"/></StackPanel></Border>
   <Border Grid.Row="4" Grid.ColumnSpan="3" Background="White" CornerRadius="14" Padding="18"><StackPanel><TextBlock Text="Recent activity" FontSize="16" FontWeight="Bold"/><TextBlock x:Name="RecentActivity" Text="InputShield started. Run a device scan to begin." Foreground="#718078" Margin="0,8,0,0"/></StackPanel></Border>
  </Grid>
  <Grid x:Name="PageDevices" Visibility="Collapsed">
   <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
   <StackPanel Grid.Row="0"><TextBlock Text="Windows input devices" FontSize="20" FontWeight="Bold"/><TextBlock Text="Read-only Plug and Play inventory. A detected device is not necessarily captured exclusively." Foreground="#718078" Margin="0,5,0,12"/></StackPanel>
   <ListView x:Name="DeviceRows" Grid.Row="1" Background="White" BorderThickness="0" MinHeight="400"><ListView.View><GridView><GridViewColumn Header="Device" Width="260" DisplayMemberBinding="{Binding Name}"/><GridViewColumn Header="Class" Width="95" DisplayMemberBinding="{Binding Class}"/><GridViewColumn Header="Status" Width="90" DisplayMemberBinding="{Binding Status}"/><GridViewColumn Header="Device ID" Width="440" DisplayMemberBinding="{Binding Id}"/></GridView></ListView.View></ListView>
  </Grid>
  <Grid x:Name="PageController" Visibility="Collapsed">
   <StackPanel>
    <TextBlock Text="Controller studio" FontSize="20" FontWeight="Bold"/><TextBlock Text="Switch Pro Controller → Xbox-style mapping profile" Foreground="#718078" Margin="0,5,0,14"/>
    <Border Background="White" CornerRadius="14" Padding="20"><StackPanel>
     <TextBlock Text="1 · Detected game controllers" FontSize="15" FontWeight="Bold"/><TextBlock x:Name="ControllerStatus" Text="Run a device scan to inspect controller devices." Foreground="#718078" TextWrapping="Wrap" Margin="0,6,0,14"/>
     <TextBlock Text="2 · Button mapping" FontSize="15" FontWeight="Bold"/>
     <Grid Margin="0,8,0,8"><Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
      <TextBlock Grid.Row="0" Grid.Column="0" Text="Switch B → Xbox" VerticalAlignment="Center"/><ComboBox x:Name="MapB" Grid.Row="0" Grid.Column="1"><ComboBoxItem Content="A"/><ComboBoxItem Content="B"/><ComboBoxItem Content="X"/><ComboBoxItem Content="Y"/></ComboBox>
      <TextBlock Grid.Row="0" Grid.Column="2" Text="Switch A → Xbox" VerticalAlignment="Center" Margin="12,0,0,0"/><ComboBox x:Name="MapA" Grid.Row="0" Grid.Column="3"><ComboBoxItem Content="A"/><ComboBoxItem Content="B"/><ComboBoxItem Content="X"/><ComboBoxItem Content="Y"/></ComboBox>
      <TextBlock Grid.Row="1" Grid.Column="0" Text="Switch Y → Xbox" VerticalAlignment="Center"/><ComboBox x:Name="MapY" Grid.Row="1" Grid.Column="1"><ComboBoxItem Content="A"/><ComboBoxItem Content="B"/><ComboBoxItem Content="X"/><ComboBoxItem Content="Y"/></ComboBox>
      <TextBlock Grid.Row="1" Grid.Column="2" Text="Switch X → Xbox" VerticalAlignment="Center" Margin="12,0,0,0"/><ComboBox x:Name="MapX" Grid.Row="1" Grid.Column="3"><ComboBoxItem Content="A"/><ComboBoxItem Content="B"/><ComboBoxItem Content="X"/><ComboBoxItem Content="Y"/></ComboBox>
     </Grid>
     <Grid Margin="0,5,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <TextBlock Grid.Column="0" Text="Stick dead zone" VerticalAlignment="Center"/><TextBox x:Name="DeadZone" Grid.Column="1" Text="0.12"/>
      <TextBlock Grid.Column="2" Text="Sensitivity (1.0 = default)" VerticalAlignment="Center" Margin="12,0,0,0"/><Slider x:Name="Sensitivity" Grid.Column="3" Minimum="0.5" Maximum="2.0" Value="1" TickFrequency="0.1" IsSnapToTickEnabled="False"/>
     </Grid>
     <CheckBox x:Name="InvertY" Content="Invert right-stick Y axis (profile setting only)" Margin="0,4,0,8"/>
     <StackPanel Orientation="Horizontal"><Button x:Name="SaveMapping" Content="Save mapping to profile"/><Button x:Name="ResetMapping" Content="Reset Switch default" Margin="8,3,0,3"/></StackPanel>
     <Border Background="#FFF4E7" CornerRadius="9" Padding="12" Margin="0,12,0,0"><TextBlock Text="IMPORTANT: this editor saves a mapping preset. The current build does not read live controller button reports and does not output a virtual Xbox controller." Foreground="#87551E" TextWrapping="Wrap"/></Border>
    </StackPanel></Border>
   </StackPanel>
  </Grid>
  <Grid x:Name="PageProfiles" Visibility="Collapsed">
   <Grid.ColumnDefinitions><ColumnDefinition Width="250"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
   <Border Grid.Column="0" Background="White" CornerRadius="12" Padding="14" Margin="0,0,12,0"><DockPanel><TextBlock DockPanel.Dock="Top" Text="Saved profiles" FontWeight="Bold" FontSize="16" Margin="0,0,0,10"/><Button x:Name="NewProfile" DockPanel.Dock="Bottom" Content="+ New profile" Margin="0,10,0,0"/><ListBox x:Name="ProfileRows" BorderThickness="0" DisplayMemberPath="Name"/></DockPanel></Border>
   <Border Grid.Column="1" Background="White" CornerRadius="12" Padding="18"><StackPanel><TextBlock Text="Profile details" FontSize="18" FontWeight="Bold"/><TextBlock Text="Profile name"/><TextBox x:Name="ProfileName" Text="Default"/><TextBlock Text="Game executable (optional)"/><DockPanel><TextBox x:Name="ProfileExe" MinWidth="250"/><Button x:Name="BrowseGame" Content="Browse…" Margin="6,4,0,8"/></DockPanel><TextBlock Text="A profile stores mapping preferences locally as JSON. It does not start or inject into the game." Foreground="#718078" TextWrapping="Wrap" Margin="0,0,0,12"/><WrapPanel><Button x:Name="SaveProfile" Content="Save profile"/><Button x:Name="DeleteProfile" Content="Delete selected" Margin="8,3,0,3"/><Button x:Name="ImportProfile" Content="Import JSON" Margin="8,3,0,3"/><Button x:Name="ExportProfile" Content="Export JSON" Margin="8,3,0,3"/></WrapPanel></StackPanel></Border>
  </Grid>
  <Grid x:Name="PageInput" Visibility="Collapsed">
   <StackPanel><TextBlock Text="Keyboard &amp; mouse" FontSize="20" FontWeight="Bold"/><TextBlock Text="Foreground-only prototype controls" Foreground="#718078" Margin="0,5,0,14"/><Border Background="White" CornerRadius="14" Padding="20"><StackPanel><TextBlock Text="Legacy input blocker" FontSize="16" FontWeight="Bold"/><TextBlock Text="The existing prototype can block low-level keyboard/mouse events only while the selected window is in the foreground. F12 is its emergency stop." TextWrapping="Wrap" Foreground="#718078" Margin="0,8,0,12"/><Button x:Name="LaunchLegacy" Content="Open foreground-only input blocker" HorizontalAlignment="Left"/><Border Background="#FFF4E7" CornerRadius="9" Padding="12" Margin="0,12,0,0"><TextBlock Text="It does NOT isolate Raw Input, DirectInput, XInput or HID per background process. It is not the solution for sending keyboard/mouse exclusively to one of two background Minecraft instances." Foreground="#87551E" TextWrapping="Wrap"/></Border></StackPanel></Border></StackPanel>
  </Grid>
  <Grid x:Name="PageDiagnostics" Visibility="Collapsed">
   <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions><StackPanel Grid.Row="0"><TextBlock Text="Diagnostics &amp; activity log" FontSize="20" FontWeight="Bold"/><TextBlock Text="Local-only records. Export a report to attach to a bug report." Foreground="#718078" Margin="0,5,0,10"/><WrapPanel><Button x:Name="ExportReport" Content="Export system report"/><Button x:Name="OpenLogFolder" Content="Open log folder" Margin="8,3,0,3"/><Button x:Name="ClearLog" Content="Clear displayed log" Margin="8,3,0,3"/></WrapPanel></StackPanel><TextBox x:Name="LogView" Grid.Row="1" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11" Background="#17271F" Foreground="#D9F3E2"/>
  </Grid>
  <Grid x:Name="PageSettings" Visibility="Collapsed">
   <StackPanel><TextBlock Text="Settings" FontSize="20" FontWeight="Bold"/><TextBlock Text="Local application configuration" Foreground="#718078" Margin="0,5,0,14"/><Border Background="White" CornerRadius="14" Padding="20"><StackPanel><TextBlock Text="Data storage" FontSize="16" FontWeight="Bold"/><TextBlock Text="Profiles, logs and settings folder"/><TextBox x:Name="DataPath" IsReadOnly="True"/><Button x:Name="OpenDataFolder" Content="Open data folder" HorizontalAlignment="Left"/><Separator Margin="0,14,0,14"/><TextBlock Text="About this build" FontSize="16" FontWeight="Bold"/><TextBlock Text="InputShield 0.3 preview · Windows PowerShell 5.1 · WPF · Local/offline" Foreground="#718078" Margin="0,6,0,4"/><TextBlock Text="No external runtime packages are required for the UI. Virtual-controller drivers are separate optional system components and are not bundled in this preview." Foreground="#718078" TextWrapping="Wrap"/></StackPanel></Border></StackPanel>
  </Grid>
 </Grid></ScrollViewer>
</Grid></Grid></Window>
'@
$window=[Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
function C([string]$name){$window.FindName($name)}
$script:PageNames=@('PageDashboard','PageDevices','PageController','PageProfiles','PageInput','PageDiagnostics','PageSettings')
$script:CurrentProfileFile=$null
function Add-Log([string]$message){
    $line='[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$message
    Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8
    if(C 'RecentActivity'){(C 'RecentActivity').Text=$message}
    if(C 'LogView'){(C 'LogView').AppendText($line+[Environment]::NewLine);(C 'LogView').ScrollToEnd()}
}
function Show-Page([string]$page,[string]$title,[string]$subtitle){
    foreach($n in $script:PageNames){(C $n).Visibility='Collapsed'}
    $map=@{dashboard='PageDashboard';devices='PageDevices';controller='PageController';profiles='PageProfiles';input='PageInput';diagnostics='PageDiagnostics';settings='PageSettings'}
    (C $map[$page]).Visibility='Visible'
    (C 'PageTitle').Text=$title;(C 'PageSub').Text=$subtitle
    if($page -eq 'diagnostics'){Load-Log}
}
function Load-Log{
    if(Test-Path -LiteralPath $script:LogFile){(C 'LogView').Text=Get-Content -LiteralPath $script:LogFile -Tail 500 -ErrorAction SilentlyContinue | Out-String}else{(C 'LogView').Text='No log entries yet.'}
}
function Refresh-Devices{
    try{
        $items=@(Get-CimInstance Win32_PnPEntity -ErrorAction Stop | Where-Object {$_.Name -match '(?i)game.?pad|controller|Nintendo|Switch|Xbox|XInput|HID-compliant game|joystick'} | ForEach-Object {[pscustomobject]@{Name=$_.Name;Class=$_.PNPClass;Status=$_.Status;Id=$_.PNPDeviceID}} | Sort-Object Name)
        (C 'DeviceRows').ItemsSource=$items;(C 'CardDeviceCount').Text=[string]$items.Count
        $controllers=@($items|Where-Object{$_.Name -match '(?i)game.?pad|controller|Nintendo|Switch|Xbox|XInput|joystick'})
        if($controllers.Count){(C 'ControllerStatus').Text=($controllers|ForEach-Object{$_.Name}) -join [Environment]::NewLine}else{(C 'ControllerStatus').Text='No matching controller device found. Connect a controller and refresh.'}
        Add-Log ("Device scan completed: {0} matching input device(s), {1} game controller(s)." -f $items.Count,$controllers.Count)
    }catch{Add-Log ("Device scan error: "+$_.Exception.Message)}
}
function Get-ProfileFiles{
    $items=@()
    Get-ChildItem -LiteralPath $script:ProfileRoot -Filter '*.json' -File -ErrorAction SilentlyContinue | ForEach-Object{
        try{$obj=Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json;$items += [pscustomobject]@{Name=[string]$obj.name;File=$_.FullName;Game=[string]$obj.gamePath}}catch{Add-Log ("Invalid profile skipped: "+$_.Name)}
    }
    return @($items|Sort-Object Name)
}
function Refresh-Profiles{
    $items=@(Get-ProfileFiles);(C 'ProfileRows').ItemsSource=$items;(C 'CardProfileCount').Text=[string]$items.Count
}
function Get-MappingFromUI{
    $mapB=[string](C 'MapB').SelectedItem.Content;$mapA=[string](C 'MapA').SelectedItem.Content;$mapY=[string](C 'MapY').SelectedItem.Content;$mapX=[string](C 'MapX').SelectedItem.Content
    $dz=0.12
    if(-not [double]::TryParse([string](C 'DeadZone').Text,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$dz)){throw 'Dead zone must be a number between 0 and 0.95.'}
    if($dz -lt 0 -or $dz -gt 0.95){throw 'Dead zone must be between 0 and 0.95.'}
    return [pscustomobject]@{switchB=$mapB;switchA=$mapA;switchY=$mapY;switchX=$mapX;deadZone=$dz;sensitivity=[math]::Round([double](C 'Sensitivity').Value,2);invertY=[bool](C 'InvertY').IsChecked}
}
function Set-MappingUI($mapping){
    if(-not $mapping){$mapping=[pscustomobject]@{switchB='A';switchA='B';switchY='X';switchX='Y';deadZone=0.12;sensitivity=1.0;invertY=$false}}
    $values=@{MapB=[string]$mapping.switchB;MapA=[string]$mapping.switchA;MapY=[string]$mapping.switchY;MapX=[string]$mapping.switchX}
    foreach($controlName in $values.Keys){$combo=C $controlName;$val=$values[$controlName];$found=$null;foreach($entry in $combo.Items){if([string]$entry.Content -eq $val){$found=$entry;break}};if($found){$combo.SelectedItem=$found}else{$combo.SelectedIndex=0}}
    (C 'DeadZone').Text=([string]$mapping.deadZone).Replace(',','.')
    (C 'Sensitivity').Value=[double]$mapping.sensitivity
    (C 'InvertY').IsChecked=[bool]$mapping.invertY
}
function Save-Profile{
    try{
        $name=([string](C 'ProfileName').Text).Trim()
        if([string]::IsNullOrWhiteSpace($name)){throw 'Enter a profile name.'}
        $slug=[regex]::Replace($name,'[^a-zA-Z0-9_-]','_')
        if([string]::IsNullOrWhiteSpace($slug)){throw 'Profile name is not valid.'}
        $mapping=Get-MappingFromUI
        $profile=[pscustomobject]@{schemaVersion=1;name=$name;gamePath=[string](C 'ProfileExe').Text;mapping=$mapping;updatedUtc=[DateTime]::UtcNow.ToString('o')}
        $path=Join-Path $script:ProfileRoot ($slug+'.json')
        $profile|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $path -Encoding UTF8
        $script:CurrentProfileFile=$path
        Refresh-Profiles;Add-Log ("Profile saved: "+$name)
        [System.Windows.MessageBox]::Show('Profile saved locally. This stores mapping preferences only; it does not create a virtual controller.','InputShield','OK','Information')|Out-Null
    }catch{[System.Windows.MessageBox]::Show($_.Exception.Message,'InputShield - profile error','OK','Warning')|Out-Null}
}
function Load-SelectedProfile{
    $selected=(C 'ProfileRows').SelectedItem
    if(-not $selected){return}
    try{
        $obj=Get-Content -LiteralPath $selected.File -Raw|ConvertFrom-Json
        (C 'ProfileName').Text=[string]$obj.name;(C 'ProfileExe').Text=[string]$obj.gamePath
        Set-MappingUI $obj.mapping;$script:CurrentProfileFile=$selected.File
        Add-Log ("Profile loaded: "+$obj.name)
    }catch{Add-Log ("Profile load failed: "+$_.Exception.Message)}
}
function Export-Profile{
    $selected=(C 'ProfileRows').SelectedItem
    $path=$script:CurrentProfileFile
    if($selected){$path=$selected.File}
    if(-not $path -or -not (Test-Path $path)){[System.Windows.MessageBox]::Show('Select or save a profile first.','InputShield')|Out-Null;return}
    $dialog=New-Object Microsoft.Win32.SaveFileDialog;$dialog.Filter='InputShield profile (*.json)|*.json';$dialog.FileName=[IO.Path]::GetFileName($path)
    if($dialog.ShowDialog()){Copy-Item -LiteralPath $path -Destination $dialog.FileName -Force;Add-Log 'Profile exported.'}
}
function Import-Profile{
    $dialog=New-Object Microsoft.Win32.OpenFileDialog;$dialog.Filter='InputShield profile (*.json)|*.json'
    if($dialog.ShowDialog()){
        try{$obj=Get-Content -LiteralPath $dialog.FileName -Raw|ConvertFrom-Json;if(-not $obj.name -or -not $obj.mapping){throw 'Invalid InputShield profile file.'};$slug=[regex]::Replace([string]$obj.name,'[^a-zA-Z0-9_-]','_');$dest=Join-Path $script:ProfileRoot ($slug+'.json');Copy-Item -LiteralPath $dialog.FileName -Destination $dest -Force;Refresh-Profiles;Add-Log ("Profile imported: "+$obj.name)}catch{[System.Windows.MessageBox]::Show($_.Exception.Message,'Import failed','OK','Warning')|Out-Null}
    }
}
function Export-SystemReport{
    try{
        $os=Get-CimInstance Win32_OperatingSystem
        $cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
        $devices=Get-CimInstance Win32_PnPEntity|Where-Object{$_.Name -match '(?i)game.?pad|controller|Nintendo|Switch|Xbox|HID-compliant game|joystick'}
        $report=@()
        $report+='InputShield diagnostic report'
        $report+=('Generated: '+(Get-Date -Format o))
        $report+=('Windows: '+$os.Caption+' '+$os.Version+' build '+$os.BuildNumber)
        $report+=('Architecture: '+$env:PROCESSOR_ARCHITECTURE)
        $report+=('PowerShell: '+$PSVersionTable.PSVersion)
        $report+=('CPU: '+$cpu.Name)
        $report+=('Profiles: '+@(Get-ProfileFiles).Count)
        $report+='';$report+='Detected controller/input devices:'
        foreach($d in $devices){$report+=(' - '+$d.Name+' | '+$d.Status+' | '+$d.PNPDeviceID)}
        $report+='';$report+='Notes: device inventory is read-only. Virtual gamepad output and per-process Raw Input isolation are not implemented.'
        $dialog=New-Object Microsoft.Win32.SaveFileDialog;$dialog.Filter='Text report (*.txt)|*.txt';$dialog.FileName='InputShield-Diagnostic-Report.txt'
        if($dialog.ShowDialog()){$report|Set-Content -LiteralPath $dialog.FileName -Encoding UTF8;Add-Log 'System report exported.'}
    }catch{[System.Windows.MessageBox]::Show($_.Exception.Message,'Report error','OK','Warning')|Out-Null}
}
function Launch-LegacyBlocker{
    $path=Join-Path $PSScriptRoot 'InputShield.ps1'
    if(-not (Test-Path -LiteralPath $path)){[System.Windows.MessageBox]::Show('Legacy prototype file not found.','InputShield')|Out-Null;return}
    $arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$path+'"'
    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments
    Add-Log 'Started legacy foreground-only keyboard/mouse blocker.'
}
# Navigation and actions
(C 'NavDashboard').Add_Click({Show-Page dashboard 'Overview' 'Devices, controller profiles and diagnostics in one place.'})
(C 'NavDevices').Add_Click({Show-Page devices 'Devices' 'Windows Plug and Play inventory.';Refresh-Devices})
(C 'NavController').Add_Click({Show-Page controller 'Controller studio' 'Edit and save controller mapping presets.';Refresh-Devices})
(C 'NavProfiles').Add_Click({Show-Page profiles 'Game profiles' 'Create, import, export and manage local profiles.';Refresh-Profiles})
(C 'NavInput').Add_Click({Show-Page input 'Keyboard & mouse' 'Experimental foreground-only controls.'})
(C 'NavDiagnostics').Add_Click({Show-Page diagnostics 'Diagnostics & logs' 'Export a local system report and inspect activity.'})
(C 'NavSettings').Add_Click({Show-Page settings 'Settings' 'Local application storage and build information.';(C 'DataPath').Text=$script:AppRoot})
(C 'RefreshAll').Add_Click({Refresh-Devices;Refresh-Profiles})
(C 'QuickController').Add_Click({Show-Page controller 'Controller studio' 'Edit and save controller mapping presets.';Refresh-Devices})
(C 'NewProfile').Add_Click({(C 'ProfileName').Text='New profile';(C 'ProfileExe').Clear();Set-MappingUI $null;$script:CurrentProfileFile=$null})
(C 'SaveProfile').Add_Click({Save-Profile})
(C 'DeleteProfile').Add_Click({
    $sel=(C 'ProfileRows').SelectedItem
    if($sel -and [System.Windows.MessageBox]::Show(('Delete profile "'+$sel.Name+'"?'),'Confirm delete','YesNo','Warning') -eq 'Yes'){Remove-Item -LiteralPath $sel.File -Force;Refresh-Profiles;$script:CurrentProfileFile=$null;Add-Log ('Profile deleted: '+$sel.Name)}
})
(C 'ProfileRows').Add_SelectionChanged({Load-SelectedProfile})
(C 'BrowseGame').Add_Click({$d=New-Object Microsoft.Win32.OpenFileDialog;$d.Filter='Windows executable (*.exe)|*.exe|All files (*.*)|*.*';if($d.ShowDialog()){(C 'ProfileExe').Text=$d.FileName}})
(C 'ImportProfile').Add_Click({Import-Profile})
(C 'ExportProfile').Add_Click({Export-Profile})
(C 'SaveMapping').Add_Click({if([string]::IsNullOrWhiteSpace((C 'ProfileName').Text)){(C 'ProfileName').Text='Default'};Save-Profile})
(C 'ResetMapping').Add_Click({Set-MappingUI $null;Add-Log 'Default Switch-to-Xbox mapping loaded in editor.'})
(C 'LaunchLegacy').Add_Click({Launch-LegacyBlocker})
(C 'ExportReport').Add_Click({Export-SystemReport})
(C 'OpenLogFolder').Add_Click({Start-Process explorer.exe $script:LogRoot})
(C 'OpenDataFolder').Add_Click({Start-Process explorer.exe $script:AppRoot})
(C 'ClearLog').Add_Click({if(Test-Path $script:LogFile){Clear-Content -LiteralPath $script:LogFile};(C 'LogView').Clear();Add-Log 'Displayed log cleared.'})
$window.Add_ContentRendered({
    Set-MappingUI $null
    Refresh-Profiles
    Refresh-Devices
    Add-Log 'InputShield desktop preview ready.'
})
$window.Add_Closing({Add-Log 'Application closed.'})
[void]$window.ShowDialog()
