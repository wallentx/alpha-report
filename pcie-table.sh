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

{
	printf 'GPU Gen Current\tGPU Width Current\tGPU Gen Capable\tGPU Width Capable\tGPU Max Gen\tHost Max Gen\n';
	printf "%s\n" \
	    "$(
          nvidia-smi \
            --query-gpu=$GPU_GEN_STAT,$GPU_WIDTH_STAT,$LINK_MAX,$LINK_WIDTH_MAX,$GPU_GEN_MAX,$HOST_GEN_MAX \
            --format=csv,noheader | \
            tr -d ',' | \
            tr ' ' '\t'
        )"; 
} | ptable 6 green
