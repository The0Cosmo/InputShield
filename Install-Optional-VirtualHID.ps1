# Optional installer launcher for a separately obtained official LizardByte Virtual HID MSI.
# This script never downloads the driver and never disables Windows security features.
$ErrorActionPreference='Stop'
$msi=Join-Path $PSScriptRoot 'packages\optional\libvirtualhid-Windows-AMD64-driver-installer.msi'
if(-not (Test-Path -LiteralPath $msi)){
    Write-Host 'Optional driver MSI is not included.' -ForegroundColor Yellow
    Write-Host 'Obtain it yourself from the official LizardByte release channel and ensure you have the required license.'
    exit 2
}
$sig=Get-AuthenticodeSignature -FilePath $msi
if($sig.Status -ne 'Valid'){
    Write-Host "Signature check failed: $($sig.Status). Driver will NOT be launched." -ForegroundColor Red
    exit 3
}
if($sig.SignerCertificate.Subject -notmatch 'LizardByte'){
    Write-Host "Unexpected publisher: $($sig.SignerCertificate.Subject). Driver will NOT be launched." -ForegroundColor Red
    exit 4
}
Write-Host 'Official optional virtual HID driver package' -ForegroundColor Cyan
Write-Host "Publisher: $($sig.SignerCertificate.Subject)"
Write-Host 'This third-party package may require a paid machine license and administrator approval.'
Write-Host 'It is not required to run the InputShield profile/diagnostics application.'
$answer=Read-Host 'Launch the signed MSI installer now? Type INSTALL to continue'
if($answer -cne 'INSTALL'){Write-Host 'Cancelled.';exit 0}
$process=Start-Process -FilePath 'msiexec.exe' -Verb RunAs -Wait -PassThru -ArgumentList ('/i "'+$msi+'"')
Write-Host "Installer exit code: $($process.ExitCode)"
