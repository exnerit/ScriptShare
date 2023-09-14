<#
.SYNOPSIS
  Deploys the Sophos Connect Client and configures it for a specific VPN profile.
.DESCRIPTION
  This script downloads and deploys the Sophos Connect Client and then configures it with the specified VPN profile.
.PARAMETER VPNProfile
  The name of the VPN profile to configure.
.EXAMPLE
  Deploy the Sophos Connect Client with the 'CustomerA' VPN profile.
  
  .\Deploy-SophosConnectClient.ps1 -VPNProfile 'CustomerA'

#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------
param(
    [parameter(Mandatory = $true)]
    [String]$VPNProfile
)

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$TempPath = "$env:TEMP\SophosConnectClient"
$SetupFile = "$TempPath\setup.msi"
$VPNConfigFolder = "C:\Program Files (x86)\Sophos\Connect\import"
$VPNConfigFile = "$VPNConfigFolder\VPN-Configuration-$VPNProfile.pro"
$url = "DOWNLOADURL" #Here your Download URL for Conenct Client Installer

#-----------------------------------------------------------[Execution]------------------------------------------------------------

if (-not(Test-Path -Path $TempPath)) {
    New-Item -Path $TempPath -ItemType Directory
}
if (-not(Test-Path -Path $VPNConfigFolder)) {
    New-Item -Path $VPNConfigFolder -ItemType Directory
}

# Download Sophos Connect Client
Write-Host "Starting download"
$ProgressPreference = 'SilentlyContinue'    # Subsequent calls do not display UI.
Invoke-WebRequest -Uri $url -OutFile $SetupFile
$ProgressPreference = 'Continue'            # Subsequent calls do display UI.

if ((Test-Path "$SetupFile") -eq "True") {
    Write-Host "Sophos Connect Client V2 successfully downloaded"
    Write-Host ""
}
else {
    Write-Host "Sophos Connect Client V2 was not downloaded"
    Write-Host ""
    Exit 1
}

# Uninstallation
Write-Host "Starting uninstallation"
Start-Process Msiexec.exe -ArgumentList "/x $SetupFile /qn /L*v $TempPath\SophosConnectClientV2.log /q" -Wait -NoNewWindow

# Deleting existing configurations
Write-Host "Deleting contents of C:\Program Files (x86)\Sophos\Connect\protected\"
Remove-Item "C:\Program Files (x86)\Sophos\Connect\protected\*.*" -Force

# Installation of Sophos Connect Client
Write-Host "Starting installation"
Start-Process Msiexec.exe -ArgumentList "/i $SetupFile /qn /L*v $TempPath\SophosConnectClientV2.log /q" -Wait -NoNewWindow

function CreateVPNConfiguration {
    $configurations = @{
        "CustomerA"     = @{
            "gateway"                   = "fqdn here"
            "user_portal_port"          = 443
            "otp"                       = $false
            "auto_connect_host"         = "" 
            "can_save_credentials"      = $true
            "check_remote_availability" = $false
            "run_logon_script"          = $false 
        }
        "CustomerB"          = @{
            "gateway"                   = "fqdn here"
            "user_portal_port"          = 4443
            "otp"                       = $false
            "auto_connect_host"         = "" 
            "can_save_credentials"      = $true
            "check_remote_availability" = $false
            "run_logon_script"          = $false 
        }
        "CustomerC"          = @{
            "gateway"                   = "fqdn here"
            "user_portal_port"          = 443
            "otp"                       = $false
            "auto_connect_host"         = "" 
            "can_save_credentials"      = $true
            "check_remote_availability" = $false
            "run_logon_script"          = $false 
        }
        "CustomerD" = @{
            "gateway"                   = "fqdn here"
            "user_portal_port"          = 4443
            "otp"                       = $false
            "auto_connect_host"         = "" 
            "can_save_credentials"      = $true
            "check_remote_availability" = $false
            "run_logon_script"          = $false 
        }
    }
    if ($configurations.ContainsKey($VPNProfile)) {
        $Configuration = $configurations[$VPNProfile] | ConvertTo-Json
    }
    else {
        Write-Host "Invalid VPN profile specified: $VPNProfile"
        Exit 1
    }

    # Create configuration file
    Write-Host "Creating configuration in $($VPNConfigFile)"
    $Configuration | Out-File -FilePath $VPNConfigFile -Force -Encoding utf8 # UTF-8 because it was generated as UTF-16 LE BOM by Ninja and wasn't read by sccli.exe or from the import folder.
}

CreateVPNConfiguration
