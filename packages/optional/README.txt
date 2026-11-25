OPTIONAL THIRD-PARTY DRIVER PACKAGE

InputShield does not bundle a third-party virtual controller driver by default.

The LizardByte Virtual HID Driver is a separate Windows package. Its Windows driver-backed virtual devices require a machine license, and the package is published for AMD64. Review the current upstream license, supported Windows versions, licensing requirements and installer signature before using it.

Official project:
https://github.com/LizardByte/libvirtualhid
Driver information:
https://app.lizardbyte.dev/libvirtualhid/virtual-hid-driver/

For a personal offline bundle only, place the official MSI at:
packages/optional/libvirtualhid-Windows-AMD64-driver-installer.msi

Then run Build-Offline-Package.ps1 -IncludeUserSuppliedVirtualHidMsi.
The build script will include that file in your private ZIP. Do not redistribute it unless the upstream license and your purchase terms explicitly permit it.

Install-Optional-VirtualHID.ps1 checks the Authenticode signature and publisher before launching the MSI with an explicit prompt and UAC. It does not bypass Windows driver security.

Important: the current InputShield preview does not yet call the libvirtualhid API or create a virtual gamepad. Installing the optional driver alone will NOT enable Switch-to-Xbox output inside InputShield.
