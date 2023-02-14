$gpuGenStat = 'pcie.link.gen.gpucurrent'
$gpuWidthStat = 'pcie.link.width.current'
$linkMax = 'pcie.link.gen.max'
$linkWidthMax = 'pcie.link.width.max'
$gpuGenMax = 'pcie.link.gen.gpumax'
$hostGenMax = 'pcie.link.gen.hostmax'

$gpuInfo = $(nvidia-smi.exe --query-gpu=$gpuGenStat,$gpuWidthStat,$linkMax,$linkWidthMax,$gpuGenMax,$hostGenMax --format=csv,noheader | ForEach-Object { $_ -replace ' ' })
$gpuGc, $gpuWc, $gpuGCap, $gpuWCap, $gpuGM, $hostGM = $gpuInfo -split ','

"GPU Gen CURRENT`tGPU Width CURRENT`tGPU Gen CAPABLE`tGPU Width CAPABLE`tGPU Gen MAX`tHost Gen MAX"
"$gpuGc`t$gpuWc`t$gpuGCap`t$gpuWCap`t$gpuGM`t$hostGM"

Write-Output "You are currently running at $($gpuGc)x$($gpuWc)."
Write-Output "You are capable of running at $($gpuGCap)x$($gpuWCap)."
Write-Output "Your GPU is able run at a max of PCIe Gen $($gpuGM)."
Write-Output "Your machine can operate at a max of PCIe Gen $($hostGM)."
