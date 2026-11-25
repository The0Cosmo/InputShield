# Removes the per-user InputShield application. Profile data is preserved by default.
$ErrorActionPreference='Stop'
$installRoot=Join-Path $env:LOCALAPPDATA 'Programs\InputShield'
$startMenu=Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\InputShield'
$choice=Read-Host 'Remove InputShield application files and shortcuts? Type YES to continue'
if($choice -cne 'YES'){Write-Host 'Cancelled.';exit 0}
if(Test-Path -LiteralPath $startMenu){Remove-Item -LiteralPath $startMenu -Recurse -Force}
if(Test-Path -LiteralPath $installRoot){Remove-Item -LiteralPath $installRoot -Recurse -Force}
Write-Host 'InputShield application removed. Local profiles and logs were preserved in %LOCALAPPDATA%\InputShield.' -ForegroundColor Green
Write-Host 'To remove personal profiles too, delete that folder manually after backing up anything you need.'
