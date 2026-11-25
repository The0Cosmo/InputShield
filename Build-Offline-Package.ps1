param([switch]$IncludeUserSuppliedVirtualHidMsi)
# Build a self-contained offline preview ZIP. UI dependencies are Windows components;
# no runtime download is performed. The optional third-party driver is excluded by default.
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$version='0.3.0-preview'
$stage=Join-Path $env:TEMP ('InputShield-Build-'+[guid]::NewGuid().ToString('N'))
$out=Join-Path $root 'release'
$zip=Join-Path $out ("InputShield-"+$version+"-Windows-x64-Offline.zip")
New-Item -ItemType Directory -Path $stage -Force | Out-Null
New-Item -ItemType Directory -Path $out -Force | Out-Null
$files=@('README.md','LICENSE','SECURITY.md','CONTRIBUTING.md','Install-InputShield.ps1','Uninstall-InputShield.ps1','Install-InputShield.cmd','Install-Optional-VirtualHID.ps1','Launch-InputShield.cmd','src\InputShield.App.ps1','src\InputShield.ps1','docs\CONTROLLER-ENGINE.md','docs\OFFLINE-DISTRIBUTION.md','packages\optional\README.txt')
foreach($relative in $files){
  $source=Join-Path $root $relative
  if(-not (Test-Path -LiteralPath $source)){throw "Required project file missing: $relative"}
  $destination=Join-Path $stage $relative
  New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
  Copy-Item -LiteralPath $source -Destination $destination -Force
}
if($IncludeUserSuppliedVirtualHidMsi){
  $msi=Join-Path $root 'packages\optional\libvirtualhid-Windows-AMD64-driver-installer.msi'
  if(-not (Test-Path -LiteralPath $msi)){throw 'Optional MSI requested but not found in packages\optional.'}
  $sig=Get-AuthenticodeSignature -FilePath $msi
  if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'LizardByte'){throw 'Optional MSI signature/publisher check failed; package stopped.'}
  $dest=Join-Path $stage 'packages\optional\libvirtualhid-Windows-AMD64-driver-installer.msi'
  Copy-Item -LiteralPath $msi -Destination $dest -Force
  $hash=(Get-FileHash -LiteralPath $msi -Algorithm SHA256).Hash
  ($hash+'  libvirtualhid-Windows-AMD64-driver-installer.msi') | Set-Content -LiteralPath (Join-Path $stage 'packages\optional\libvirtualhid.sha256.txt') -Encoding ASCII
}
@"
InputShield $version - OFFLINE PREVIEW

INSTALL
1. Extract this ZIP.
2. Double-click Install-InputShield.cmd.
3. Open InputShield from the Start Menu.
4. No internet connection or administrator rights are required for the app itself.

INCLUDED
- InputShield desktop application (Windows PowerShell 5.1 + WPF)
- Windows Plug and Play device inventory
- Local game profiles and editable Switch/Xbox mapping presets
- Profile import/export, system report and local logs
- Per-user installer and uninstaller
- Source, MIT licence and documentation

NOT IMPLEMENTED
- Actual virtual Xbox gamepad output
- Live controller button/axis capture
- Per-background-process Raw Input/DirectInput/XInput isolation

THIRD-PARTY DRIVER
The optional Virtual HID driver is not included by default. If you supplied your own official MSI and explicitly enabled the packaging switch, it is included only in your personal ZIP. Driver-backed virtual devices require a valid provider licence. Installing that driver alone does not activate InputShield virtual output.

APP DATA
Profiles and logs are stored separately under %LOCALAPPDATA%\InputShield and are preserved when uninstalling the app.
"@ | Set-Content -LiteralPath (Join-Path $stage 'OFFLINE-START-HERE.txt') -Encoding UTF8
if(Test-Path -LiteralPath $zip){Remove-Item -LiteralPath $zip -Force}
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
$hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
($hash+'  '+(Split-Path -Leaf $zip)) | Set-Content -LiteralPath ($zip+'.sha256') -Encoding ASCII
Remove-Item -LiteralPath $stage -Recurse -Force
Write-Host 'OFFLINE PACKAGE CREATED' -ForegroundColor Green
Write-Host $zip
Write-Host ('SHA256: '+$hash)
