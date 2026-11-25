# Creates an offline ZIP bundle for the current prototype.
# Run from any Windows PowerShell 5.1 session; no admin rights or internet required.
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$version='0.2.0-preview'
$stage=Join-Path $env:TEMP ("InputShield-Offline-"+[guid]::NewGuid().ToString('N'))
$out=Join-Path $root 'release'
$zip=Join-Path $out ("InputShield-"+$version+"-Windows-x64-Offline.zip")
New-Item -ItemType Directory -Path $stage -Force | Out-Null
New-Item -ItemType Directory -Path $out -Force | Out-Null
$files=@('README.md','LICENSE','SECURITY.md','CONTRIBUTING.md','Launch-InputShield.cmd','src\InputShield.Modern.ps1','src\InputShield.ps1','docs\CONTROLLER-ENGINE.md','docs\OFFLINE-DISTRIBUTION.md')
foreach($relative in $files){
  $source=Join-Path $root $relative
  if(Test-Path -LiteralPath $source){
    $destination=Join-Path $stage $relative
    $parent=Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
  } else { throw "Required project file missing: $relative" }
}
@"
InputShield $version
Offline preview bundle

1. Extract this archive.
2. Double-click Launch-InputShield.cmd.
3. The application runs locally using Windows PowerShell 5.1 and WPF.
4. No internet connection or administrator rights are required for this UI preview.

IMPORTANT:
This preview does not provide Switch-to-Xbox virtual controller output.
It does not provide reliable background-process Raw Input isolation.
Do not install third-party drivers from untrusted sources.
"@ | Set-Content -LiteralPath (Join-Path $stage 'OFFLINE-START-HERE.txt') -Encoding UTF8
if(Test-Path -LiteralPath $zip){Remove-Item -LiteralPath $zip -Force}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
$hash=Get-FileHash -LiteralPath $zip -Algorithm SHA256
"$($hash.Hash)  $(Split-Path -Leaf $zip)" | Set-Content -LiteralPath ($zip+'.sha256') -Encoding ASCII
Remove-Item -LiteralPath $stage -Recurse -Force
Write-Host "OFFLINE PACKAGE CREATED" -ForegroundColor Green
Write-Host $zip
Write-Host "SHA256: $($hash.Hash)"
