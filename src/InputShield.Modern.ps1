# InputShield UI shell - Windows PowerShell 5.1, WPF built into Windows.
# Device inventory is functional; virtual Xbox output is not implemented in this build.
$ErrorActionPreference='Stop'
if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  $argsList=@('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File',$PSCommandPath)
  Start-Process -FilePath 'powershell.exe' -ArgumentList $argsList
  exit
}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
[xml]$xaml=@'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="InputShield" Width="1100" Height="700" MinWidth="950" MinHeight="600" WindowStartupLocation="CenterScreen" Background="#F2F6F3" FontFamily="Segoe UI">
<Grid><Grid.ColumnDefinitions><ColumnDefinition Width="220"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
<Border Background="#17271F"><StackPanel Margin="18"><TextBlock Text="◈ INPUTSHIELD" Foreground="#F0FFF4" FontSize="20" FontWeight="Bold" Margin="0,10,0,28"/>
<Button x:Name="Home" Content="⌂   Overview" Background="#315C43" Foreground="White" Padding="12" Margin="0,0,0,8"/>
<Button x:Name="Devices" Content="▣   Devices" Background="#294333" Foreground="White" Padding="12" Margin="0,0,0,8"/>
<Button x:Name="Controller" Content="◉   Controller studio" Background="#294333" Foreground="White" Padding="12" Margin="0,0,0,8"/>
<Button x:Name="Profiles" Content="▤   Game profiles" Background="#294333" Foreground="White" Padding="12" Margin="0,0,0,8"/>
<Button x:Name="Input" Content="⌨   Keyboard & mouse" Background="#294333" Foreground="White" Padding="12" Margin="0,0,0,8"/>
<Button x:Name="Settings" Content="⚙   Settings" Background="#294333" Foreground="White" Padding="12" Margin="0,0,0,8"/>
<Border Background="#294333" CornerRadius="10" Padding="12" Margin="0,220,0,0"><StackPanel><TextBlock Text="OFFLINE READY" Foreground="#A9E6BC" FontWeight="Bold"/><TextBlock Text="Local mode · No cloud" Foreground="White" Margin="0,5,0,0"/></StackPanel></Border>
</StackPanel></Border>
<Grid Grid.Column="1" Margin="28"><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
<Grid Grid.Row="0" Margin="0,0,0,20"><StackPanel><TextBlock x:Name="PageTitle" Text="Overview" FontSize="29" FontWeight="Bold" Foreground="#19271F"/><TextBlock x:Name="PageSub" Text="Your devices, profiles and input controls — all in one place." Foreground="#718078" Margin="0,5,0,0"/></StackPanel><Button x:Name="Refresh" Content="↻ Refresh devices" HorizontalAlignment="Right" VerticalAlignment="Center" Padding="16,10"/></Grid>
<ScrollViewer Grid.Row="1"><StackPanel>
<Grid x:Name="Dashboard"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><Grid.RowDefinitions><RowDefinition Height="120"/><RowDefinition Height="18"/><RowDefinition Height="210"/><RowDefinition Height="18"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
<Border Grid.Column="0" Background="White" CornerRadius="14" Padding="18" Margin="0,0,8,0"><StackPanel><TextBlock Text="CONNECTED DEVICES" Foreground="#718078" FontSize="10" FontWeight="Bold"/><TextBlock x:Name="DeviceCount" Text="—" FontSize="34" FontWeight="Bold" Margin="0,7,0,0"/><TextBlock Text="Detected on this PC" Foreground="#718078"/></StackPanel></Border>
<Border Grid.Column="1" Background="White" CornerRadius="14" Padding="18" Margin="4,0"><StackPanel><TextBlock Text="GAME PROFILES" Foreground="#718078" FontSize="10" FontWeight="Bold"/><TextBlock Text="0" FontSize="34" FontWeight="Bold" Margin="0,7,0,0"/><TextBlock Text="Per-game configurations" Foreground="#718078"/></StackPanel></Border>
<Border Grid.Column="2" Background="White" CornerRadius="14" Padding="18" Margin="8,0,0,0"><StackPanel><TextBlock Text="VIRTUAL XBOX OUTPUT" Foreground="#718078" FontSize="10" FontWeight="Bold"/><TextBlock Text="NOT READY" Foreground="#A56A20" FontSize="20" FontWeight="Bold" Margin="0,10,0,0"/><TextBlock Text="Provider integration pending" Foreground="#718078"/></StackPanel></Border>
<Border Grid.Row="2" Grid.ColumnSpan="2" Background="White" CornerRadius="14" Padding="20" Margin="0,0,8,0"><StackPanel><TextBlock Text="Controller studio" FontSize="18" FontWeight="Bold"/><TextBlock Text="Inspect gamepads and prepare per-game layouts, including Switch Pro to Xbox-style mapping." Foreground="#718078" TextWrapping="Wrap" Margin="0,8,0,15"/><Border Background="#EFF8F1" CornerRadius="10" Padding="14"><StackPanel><TextBlock Text="SWITCH → XBOX WORKFLOW" Foreground="#28784D" FontSize="10" FontWeight="Bold"/><TextBlock Text="Physical controller → Mapping → Virtual Xbox device" FontSize="14" FontWeight="SemiBold" Margin="0,8,0,4"/><TextBlock Text="Virtual-device output is not implemented in this prototype." Foreground="#718078"/></StackPanel></Border><Button x:Name="OpenStudio" Content="Open controller studio →" HorizontalAlignment="Left" Margin="0,14,0,0"/></StackPanel></Border>
<Border Grid.Row="2" Grid.Column="2" Background="#20392B" CornerRadius="14" Padding="18" Margin="8,0,0,0"><StackPanel><TextBlock Text="SAFETY FIRST" Foreground="#A9E6BC" FontWeight="Bold"/><TextBlock Text="Always in control." Foreground="White" FontSize="20" FontWeight="Bold" Margin="0,10,0,8"/><TextBlock Text="Visible stop controls, clear device status and no silent driver installation." Foreground="#D5E9DB" TextWrapping="Wrap"/></StackPanel></Border>
<Border Grid.Row="4" Grid.ColumnSpan="3" Background="White" CornerRadius="14" Padding="18"><StackPanel><TextBlock Text="Recent activity" FontSize="16" FontWeight="Bold"/><TextBlock x:Name="Activity" Text="Ready. Run a device scan to begin." Foreground="#718078" Margin="0,8,0,0"/></StackPanel></Border></Grid>
<Grid x:Name="DevicePanel" Visibility="Collapsed"><StackPanel><TextBlock Text="Detected input devices" FontSize="20" FontWeight="Bold" Margin="0,0,0,12"/><ListView x:Name="DeviceRows" Background="White" BorderThickness="0" MinHeight="400"><ListView.View><GridView><GridViewColumn Header="Device" Width="280" DisplayMemberBinding="{Binding Name}"/><GridViewColumn Header="Class" Width="100" DisplayMemberBinding="{Binding Class}"/><GridViewColumn Header="Status" Width="100" DisplayMemberBinding="{Binding Status}"/><GridViewColumn Header="Device ID" Width="400" DisplayMemberBinding="{Binding Id}"/></GridView></ListView.View></ListView></StackPanel></Grid>
<Grid x:Name="StudioPanel" Visibility="Collapsed"><StackPanel><TextBlock Text="Controller studio" FontSize="20" FontWeight="Bold"/><TextBlock Text="Nintendo Switch Pro Controller → Xbox-compatible layout" Foreground="#718078" Margin="0,5,0,18"/><Border Background="White" CornerRadius="14" Padding="22"><StackPanel><TextBlock Text="1 · Physical controller" FontSize="16" FontWeight="Bold"/><TextBlock x:Name="ControllerStatus" Text="Run Refresh devices to inspect controllers." Foreground="#718078" Margin="0,8,0,18"/><TextBlock Text="2 · Mapping preview" FontSize="16" FontWeight="Bold"/><TextBlock Text="Switch: B → Xbox A     A → Xbox B     Y → Xbox X     X → Xbox Y" FontSize="16" FontWeight="SemiBold" Margin="0,12,0,18"/><Border Background="#FFF4E7" CornerRadius="10" Padding="13"><TextBlock Text="Virtual Xbox output is not available yet. A compatible signed virtual-device provider must be integrated and installed before games can detect a virtual controller." Foreground="#87551E" TextWrapping="Wrap"/></Border></StackPanel></Border></StackPanel></Grid>
<Grid x:Name="OtherPanel" Visibility="Collapsed"><Border Background="White" CornerRadius="14" Padding="24"><StackPanel><TextBlock x:Name="OtherTitle" Text="Coming soon" FontSize="20" FontWeight="Bold"/><TextBlock Text="This section is planned but not implemented yet." Foreground="#718078" Margin="0,8,0,0"/></StackPanel></Border></Grid>
</StackPanel></ScrollViewer></Grid></Grid></Window>
'@
$window=[Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
function C($n){$window.FindName($n)}
$dash=C 'Dashboard';$dev=C 'DevicePanel';$studio=C 'StudioPanel';$other=C 'OtherPanel'
function Page($mode,$title,$sub){$dash.Visibility='Collapsed';$dev.Visibility='Collapsed';$studio.Visibility='Collapsed';$other.Visibility='Collapsed';switch($mode){home{$dash.Visibility='Visible'} devices{$dev.Visibility='Visible'} controller{$studio.Visibility='Visible'} default{$other.Visibility='Visible';(C 'OtherTitle').Text=$title}};(C 'PageTitle').Text=$title;(C 'PageSub').Text=$sub}
function Scan {
 try {$items=@(Get-CimInstance Win32_PnPEntity | Where-Object {$_.Name -match '(?i)game.?pad|controller|Nintendo|Switch Pro|Xbox|XInput|HID-compliant game'} | ForEach-Object {[pscustomobject]@{Name=$_.Name;Class=$_.PNPClass;Status=$_.Status;Id=$_.PNPDeviceID}} | Sort-Object Name);(C 'DeviceRows').ItemsSource=$items;(C 'DeviceCount').Text=[string]$items.Count;(C 'Activity').Text="Scan completata: $($items.Count) dispositivo/i rilevato/i."; (C 'ControllerStatus').Text=if($items.Count){($items|ForEach-Object{$_.Name}) -join [Environment]::NewLine}else{'Nessun controller individuato.'}}
 catch {(C 'Activity').Text="Errore scansione: $($_.Exception.Message)"}
}
(C 'Home').Add_Click({Page home 'Overview' 'Your devices, profiles and input controls — all in one place.'})
(C 'Devices').Add_Click({Page devices 'Devices' 'Connected and detected input devices.';Scan})
(C 'Controller').Add_Click({Page controller 'Controller studio' 'Inspect devices and review Switch-to-Xbox mapping.';Scan})
(C 'OpenStudio').Add_Click({Page controller 'Controller studio' 'Inspect devices and review Switch-to-Xbox mapping.';Scan})
(C 'Profiles').Add_Click({Page profiles 'Game profiles' 'Per-game controller and input configurations.'})
(C 'Input').Add_Click({Page input 'Keyboard & mouse' 'Input routing and isolation controls.'})
(C 'Settings').Add_Click({Page settings 'Settings' 'Appearance and local preferences.'})
(C 'Refresh').Add_Click({Scan})
$window.Add_ContentRendered({Scan})
[void]$window.ShowDialog()
