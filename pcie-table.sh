#!/usr/bin/env bash
set -euo pipefail


# The current PCI-E link generation. These may be reduced when the GPU is not in use.
GPU_GEN_STAT=pcie.link.gen.gpucurrent

# The current PCI-E link width. These may be reduced when the GPU is not in use.
GPU_WIDTH_STAT=pcie.link.width.current

# The maximum PCI-E link generation possible with this GPU and system configuration.
# For example, if the GPU supports a higher PCIe generation than the system supports,
# then this reports the system PCIe generation.
LINK_MAX=pcie.link.gen.max

# The maximum PCI-E link width possible with this GPU and system configuration.
# For example, if the GPU supports a higher PCIe generation than the system supports,
# then this reports the system PCIe generation.
LINK_WIDTH_MAX=pcie.link.width.max

# The maximum PCI-E link generation supported by this GPU.
GPU_GEN_MAX=pcie.link.gen.gpumax

# The maximum PCI-E link generation supported by the root port corresponding to this GPU.
HOST_GEN_MAX=pcie.link.gen.hostmax

GPUINFO=$(nvidia-smi --query-gpu=$GPU_GEN_STAT,$GPU_WIDTH_STAT,$LINK_MAX,$LINK_WIDTH_MAX,$GPU_GEN_MAX,$HOST_GEN_MAX --format=csv,noheader | tr -d ' ' )
IFS=',' read -r GPU_G_C GPU_W_C GPU_G_CAP GPU_W_CAP GPU_G_M HOST_G_M <<< "$GPUINFO"


{
	printf 'GPU Gen CURRENT\tGPU Width CURRENT\tGPU Gen CAPABLE\tGPU Width CAPABLE\tGPU Gen MAX\tHost Gen MAX\n';
	printf "%s\n" ''$GPU_G_C'\t'$GPU_W_C'\t'$GPU_G_CAP'\t'$GPU_W_CAP'\t'$GPU_G_M'\t'$HOST_G_M'\n';
} | ./extra/ptable 6 green

echo "You are currently running at "$GPU_G_C"x"$GPU_W_C"."
echo "You are capable of running at "$GPU_G_CAP"x"$GPU_W_CAP"."
echo "Your card is able run at a max PCIe Gen of "$GPU_G_M"."
echo "Your host can operate at a max of PCIe Gen "$HOST_G_M"."
