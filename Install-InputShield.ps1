# Installs InputShield for the current Windows user; administrator rights are not required.
$ErrorActionPreference='Stop'
$sourceRoot=Split-Path -Parent $MyInvocation.MyCommand.Path
$installRoot=Join-Path $env:LOCALAPPDATA 'Programs\InputShield'
$startMenu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\InputShield'
$required=@('src\InputShield.App.ps1','src\InputShield.ps1','Launch-InputShield.cmd','LICENSE')
foreach($item in $required){if(-not (Test-Path -LiteralPath (Join-Path $sourceRoot $item))){throw "Package incomplete: missing $item"}}
New-Item -ItemType Directory -Path $installRoot,$startMenu -Force | Out-Null
foreach($folder in @('src','docs','packages')) {
  $from=Join-Path $sourceRoot $folder
  if(Test-Path -LiteralPath $from){Copy-Item -LiteralPath $from -Destination $installRoot -Recurse -Force}
}
foreach($file in @('README.md','LICENSE','SECURITY.md','CONTRIBUTING.md','Launch-InputShield.cmd','Uninstall-InputShield.ps1','Install-Optional-VirtualHID.ps1')) {
  $from=Join-Path $sourceRoot $file
  if(Test-Path -LiteralPath $from){Copy-Item -LiteralPath $from -Destination $installRoot -Force}
}
$psExe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$appScript=Join-Path $installRoot 'src\InputShield.App.ps1'
$ws=New-Object -ComObject WScript.Shell
$shortcut=$ws.CreateShortcut((Join-Path $startMenu 'InputShield.lnk'))
$shortcut.TargetPath=$psExe
$shortcut.Arguments='-NoProfile -ExecutionPolicy Bypass -STA -File "'+$appScript+'"'
$shortcut.WorkingDirectory=$installRoot
$shortcut.Description='InputShield local input profile and diagnostics tool'
$shortcut.IconLocation=$psExe+',0'
$shortcut.Save()
$uninstall=$ws.CreateShortcut((Join-Path $startMenu 'Uninstall InputShield.lnk'))
$uninstall.TargetPath=$psExe
$uninstall.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $installRoot 'Uninstall-InputShield.ps1')+'"'
$uninstall.WorkingDirectory=$installRoot
$uninstall.Description='Uninstall InputShield'
$uninstall.Save()
Write-Host ''
Write-Host 'InputShield installed for the current user.' -ForegroundColor Green
Write-Host "Application: $installRoot"
Write-Host "Start Menu: $startMenu"
Write-Host 'Profiles and logs remain in %LOCALAPPDATA%\InputShield.'
Write-Host 'No driver was installed. Virtual Xbox output is not available in this preview.'
