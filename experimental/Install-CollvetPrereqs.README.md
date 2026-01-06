# Collvet Prerequisites Bootstrapper

This PowerShell script automates the installation of prerequisites required for Collvet development and deployment.

## Features

- **Self-elevates to Administrator** (with option to skip via `-NoElevate`)
- **Installs PowerShell Modules:**
  - `O365CentralizedAddInDeployment` - Centralized Deployment cmdlets for Office add-ins
  - `Microsoft.Graph` - Microsoft Graph PowerShell SDK (minimum version 2.0.0)
- **Installs Power Platform CLI (`pac`)** with multiple fallback methods:
  1. **Winget** (primary/fastest method)
  2. **MSI installer** (optional, via `-PacMsiPath` parameter)
  3. **.NET tool** (secondary fallback)

## Usage

### Basic Usage
```powershell
.\experimental\Install-CollvetPrereqs.ps1
```
This will automatically self-elevate to Administrator and install all prerequisites.

### Skip Admin Elevation
```powershell
.\experimental\Install-CollvetPrereqs.ps1 -NoElevate
```
Use this if you're already running as Administrator or don't have admin rights (some installations may fail).

### Use MSI Installer for Power Platform CLI
```powershell
.\experimental\Install-CollvetPrereqs.ps1 -PacMsiPath "C:\path\to\powerapps-cli-1.0.msi"
```
If you've already downloaded the Power Platform CLI MSI installer, you can specify its path.

## Requirements

- **Windows PowerShell 5.1** or **PowerShell 7+**
- **Internet connection** for downloading modules and tools
- **Administrator privileges** (recommended) for full installation

## Installation Methods

### Power Platform CLI Installation Priority

The script tries installation methods in this order:

1. **Winget** - Fastest method if Windows Package Manager is available
2. **MSI** - Used if `-PacMsiPath` parameter is provided
3. **.NET Tool** - Used if dotnet CLI is available and other methods fail

If all methods fail, the script will throw an error with helpful guidance.

## Troubleshooting

### Module Installation Fails
- Ensure you have an internet connection
- Check that PowerShell Gallery is accessible: `Test-NetConnection -ComputerName www.powershellgallery.com -Port 443`
- Try running with Administrator privileges

### Power Platform CLI Installation Fails
- **Winget not found**: Install Windows Package Manager from the Microsoft Store
- **MSI method**: Download the latest MSI from [Microsoft's documentation](https://learn.microsoft.com/en-us/power-platform/developer/howto/install-cli-msi)
- **.NET tool method**: Install .NET SDK from [dotnet.microsoft.com](https://dotnet.microsoft.com/download)

### Script Won't Elevate
- Ensure User Account Control (UAC) is enabled
- Try running PowerShell as Administrator manually first
- Use `-NoElevate` parameter if you're already running as admin

## Security

- The script uses `Set-StrictMode -Version Latest` for better error detection
- Exit codes are checked for all external commands
- URLs are displayed instead of automatically opening browsers
- All PowerShell modules are installed from the official PowerShell Gallery

## Additional Resources

- [O365 Centralized Add-In Deployment](https://learn.microsoft.com/en-us/office/dev/add-ins/publish/centralized-deployment)
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction)
