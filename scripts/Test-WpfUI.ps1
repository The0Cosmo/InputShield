# Headless WPF load test. Run from Windows PowerShell 5.1 in STA mode.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$appFile=Join-Path (Split-Path -Parent $PSScriptRoot) 'src\InputShield.App.ps1'
if(-not (Test-Path -LiteralPath $appFile)){throw "Missing app file: $appFile"}
$source=Get-Content -LiteralPath $appFile -Raw
$startMarker='[xml]$xaml=@'+[char]39
$endMarker=[char]39+'@'
$start=$source.IndexOf($startMarker,[StringComparison]::Ordinal)
if($start -lt 0){throw 'XAML start marker not found.'}
$from=$source.IndexOf([char]10,$start)+1
$to=$source.IndexOf($endMarker,$from,[StringComparison]::Ordinal)
if($to -lt $from){throw 'XAML end marker not found.'}
$xamlText=$source.Substring($from,$to-$from)
$reader=New-Object System.Xml.XmlNodeReader ([xml]$xamlText)
$window=[Windows.Markup.XamlReader]::Load($reader)
$required=@('NavDashboard','NavDevices','NavController','NavProfiles','NavInput','NavDiagnostics','NavSettings','DeviceRows','MapB','MapA','MapY','MapX','ProfileRows','SaveProfile','ExportReport','LogView')
foreach($name in $required){
    if($null -eq $window.FindName($name)){throw "WPF named control not found: $name"}
}
Write-Host ("WPF XAML loaded successfully. Verified {0} named controls." -f $required.Count) -ForegroundColor Green
