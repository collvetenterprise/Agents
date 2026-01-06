<#
Collvet Prereqs Bootstrapper
- Prompts for admin privileges (self-elevates)
- Installs:
  - O365CentralizedAddInDeployment (Centralized Deployment cmdlets)  [3](https://learn.microsoft.com/en-us/sharepoint/dev/features/hub-site/create-hub-site-with-powershell)[4](https://pnp.github.io/powershell/cmdlets/Register-PnPHubSite.html)
  - Microsoft.Graph (Graph PowerShell SDK) [5](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/review-copilot-prs)[6](https://docs.github.com/en/copilot/tutorials/explore-pull-requests)
  - Power Platform CLI (pac) via winget; fallback MSI; fallback .NET tool [1](https://www.microsoft.com/content/dam/microsoft/msc/documents/presentations/nonprofits/pdfs/Microsoft-Nonprofit-Offers-Guide.pdf)[2](https://support.techsoup.org/hc/en-us/articles/12968116130075-How-do-I-access-donated-and-discounted-Microsoft-for-Nonprofits-products-on-TechSoup)
#>

[CmdletBinding()]
param(
  [switch]$NoElevate,
  [string]$PacMsiPath = ""   # Optional: path to powerapps-cli-1.0.msi if you already downloaded it
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Elevation {
  if ($NoElevate) { return }
  if (-not (Test-IsAdmin)) {
    Write-Host "Admin privileges are recommended for full prereq installation." -ForegroundColor Yellow
    Write-Host "Relaunching as Administrator..." -ForegroundColor Yellow

    $argsList = @()
    if ($PacMsiPath) { $argsList += "-PacMsiPath `"$PacMsiPath`"" }

    $argString = @(
      "-NoProfile",
      "-ExecutionPolicy Bypass",
      "-File `"$PSCommandPath`"",
      ($argsList -join " ")
    ) -join " "

    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argString | Out-Null
    exit
  }
}

function Ensure-PSModule {
  param(
    [Parameter(Mandatory)][string]$Name,
    [string]$MinimumVersion = ""
  )
  $existing = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
  if ($existing) {
    if ($MinimumVersion -and ([version]$existing.Version -lt [version]$MinimumVersion)) {
      Write-Host "Updating module $Name (current $($existing.Version) < min $MinimumVersion)..." -ForegroundColor Yellow
      Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber
    } else {
      Write-Host "Module OK: $Name ($($existing.Version))" -ForegroundColor Green
    }
  } else {
    Write-Host "Installing module: $Name" -ForegroundColor Yellow
    Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber
  }
}

function Test-Winget {
  try { & winget --version | Out-Null; return $true } catch { return $false }
}

function Ensure-WingetPackage {
  param([Parameter(Mandatory)][string]$Id)
  if (-not (Test-Winget)) { return $false }

  Write-Host "Installing via winget: $Id" -ForegroundColor Yellow
  & winget install -e --id $Id --silent --accept-package-agreements --accept-source-agreements | Out-Null
  return $true
}

function Ensure-PowerPlatformCLI {
  # 1) Try winget first (fast path)
  $wingetOk = Ensure-WingetPackage -Id "Microsoft.PowerAppsCLI"
  if ($wingetOk -and (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Host "✅ pac installed via winget." -ForegroundColor Green
    return
  }

  # 2) Default fallback: MSI (your preference)  [1](https://www.microsoft.com/content/dam/microsoft/msc/documents/presentations/nonprofits/pdfs/Microsoft-Nonprofit-Offers-Guide.pdf)[7](https://nonprofit.microsoft.com/en-us/getting-started)
  if ($PacMsiPath -and (Test-Path $PacMsiPath)) {
    Write-Host "Installing Power Platform CLI via MSI: $PacMsiPath" -ForegroundColor Yellow
    Start-Process "msiexec.exe" -ArgumentList "/i `"$PacMsiPath`" /qn /norestart" -Wait
    if (Get-Command pac -ErrorAction SilentlyContinue) {
      Write-Host "✅ pac installed via MSI." -ForegroundColor Green
      return
    }
  } else {
    Write-Warning "MSI fallback selected but PacMsiPath not provided."
    Write-Host "Microsoft's MSI method: download and run powerapps-cli-1.0.msi." -ForegroundColor Gray
    Write-Host "Docs: Install Power Platform CLI using Windows MSI." -ForegroundColor Gray
    # Open docs to download instructions (interactive)
    Start-Process "https://learn.microsoft.com/en-us/power-platform/developer/howto/install-cli-msi" | Out-Null
  }

  # 3) Secondary fallback: .NET tool  [2](https://support.techsoup.org/hc/en-us/articles/12968116130075-How-do-I-access-donated-and-discounted-Microsoft-for-Nonprofits-products-on-TechSoup)[8](https://learn.microsoft.com/en-us/industry/nonprofit/microsoft-for-nonprofits/nonprofit-offerings-products)
  if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    Write-Host "Trying .NET tool fallback for Power Platform CLI..." -ForegroundColor Yellow
    & dotnet tool update --global Microsoft.PowerApps.CLI.Tool 2>$null
    if ($LASTEXITCODE -ne 0) {
      & dotnet tool install --global Microsoft.PowerApps.CLI.Tool
    }
    if (Get-Command pac -ErrorAction SilentlyContinue) {
      Write-Host "✅ pac installed via .NET tool." -ForegroundColor Green
      return
    }
  } else {
    Write-Warning "dotnet not found; cannot use .NET tool fallback."
    Write-Host "Docs: Install Power Platform CLI with .NET Tool." -ForegroundColor Gray
    Start-Process "https://learn.microsoft.com/en-us/power-platform/developer/howto/install-cli-net-tool" | Out-Null
  }

  throw "Failed to install Power Platform CLI (pac)."
}

# ---- Execution ----
Ensure-Elevation

Write-Host "=== Collvet Prereqs Installer ===" -ForegroundColor Cyan

# Centralized Deployment module (Office add-ins)  [3](https://learn.microsoft.com/en-us/sharepoint/dev/features/hub-site/create-hub-site-with-powershell)[4](https://pnp.github.io/powershell/cmdlets/Register-PnPHubSite.html)
Ensure-PSModule -Name "O365CentralizedAddInDeployment"

# Graph SDK  [5](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/review-copilot-prs)[6](https://docs.github.com/en/copilot/tutorials/explore-pull-requests)
Ensure-PSModule -Name "Microsoft.Graph" -MinimumVersion "2.0.0"

# Power Platform CLI: winget → MSI (default fallback) → .NET tool fallback  [1](https://www.microsoft.com/content/dam/microsoft/msc/documents/presentations/nonprofits/pdfs/Microsoft-Nonprofit-Offers-Guide.pdf)[2](https://support.techsoup.org/hc/en-us/articles/12968116130075-How-do-I-access-donated-and-discounted-Microsoft-for-Nonprofits-products-on-TechSoup)
Ensure-PowerPlatformCLI

Write-Host "✅ All requested prerequisites processed." -ForegroundColor Green
