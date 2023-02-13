# $ErrorActionPreference= 'silentlycontinue'

function Get-WmiMemoryFormFactor {
    [CmdletBinding()]
    param (
        [int]$MemoryType
    )

    $formFactors = @{
        20 = "DDR"
        21 = "DDR2"
        24 = "DDR3"
        26 = "DDR4"
        30 = "DDR5"
    }
    $formFactors[$MemoryType]
}

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin)
{
    Write-Warning "Insufficient permissions to run this script. Open PowerShell as an administrator and run this script again."
    Exit
}

# Get system info
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$proc = Get-CimInstance -ClassName Win32_Processor
$vc = Get-CimInstance -ClassName Win32_VideoController
$pm = Get-CimInstance -ClassName Win32_PhysicalMemory    
# Determine the number of DIMMs and their capacity
$pma = $pm | Select-Object @{n="Capacity";e={"$([int64]($_.Capacity/1GB))GB"}}, @{n="Speed";e={"$($_.Speed)MT/s"}}
$pmp = $pma | Group-Object Capacity | Select-Object Count, Name | Select-Object @{n="Capacity";e={$_.Name}}, @{n="Count";e={$_.Count}}
$formFactors = Get-WmiMemoryFormFactor -MemoryType $pm.MemoryType[0]
$dramCapacity = "$([int64]($pm.Capacity | Measure-Object -Sum).Sum / 1GB)GB"
$dramDimms = $pmp | ForEach-Object { "$($_.Count)x$($_.Capacity)" }
$dramSpeed = $pma[0].Speed    
# Get NVIDIA GPU PCIe link info
$nvInfo = (nvidia-smi.exe --query-gpu=pcie.link.gen.current,pcie.link.width.current,driver_version --format=csv,noheader)
$nvData = $nvInfo -split ","
$nvGen = $nvData[0] -replace '\s'
$nvWidth = $nvData[1] -replace '\s'
$nvDriver = $nvData[2] -replace '\s'

# System Name
Write-Output "SystemName=`"$($cs.Name)`""

# OS
Write-Output "OS=`"$($os.Caption) $($os.Version)`""

# SystemVendor/Model
Write-Output "SystemVendor/Model=`"$($cs.Manufacturer)/$($cs.Model)`""

# CPU
Write-Output "CPU=`"$($proc.Name) (C:$($proc.NumberOfCores)|T:$($proc.NumberOfLogicalProcessors))`""

# GPU
Write-Output "GPU=`"$($vc.Name)`""

# NVIDIA Driver
Write-Output "DriverVersion=`"$nvDriver`""

# PCIe link
Write-Output "PCIeLink=`"PCIe $nvGen x$nvWidth`""

# DRAM (Size, Type, MHz, etc)
Write-Output "DRAM=`"$dramCapacity, $dramDimms $formFactors, $dramSpeed`""
