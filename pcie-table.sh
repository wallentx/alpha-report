#!/usr/bin/env bash
set -e

source ./extra/spinner

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

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

# When persistence mode is enabled, the NVIDIA driver remains loaded even when no active clients,
# such as X11 or nvidia-smi, exist.
# This minimizes the driver load latency associated with running dependent apps, such as CUDA programs.
# Linux only.

function queryLink() {
  IFS=',' W_ARRAY=( $(nvidia-smi --query-gpu=power.max_limit,power.default_limit,persistence_mode,pstate --format=csv,noheader | sed 's/, /,/g; s/ W//g') )
  W_MAX=$(echo ${W_ARRAY[0]} | awk '{printf "%.0f\n", $1}')
  W_DEF=$(echo ${W_ARRAY[1]} | awk '{printf "%.0f\n", $1}')
  P_MODE=$(echo ${W_ARRAY[2]})
  P_STATE=$(echo ${W_ARRAY[3]})
#  P_MAX=sudo nvidia-smi -pl "$W_MAX" &>/dev/null
#  P_DEF=sudo nvidia-smi -pl "$W_DEF" &>/dev/null
  GPUINFO=$(nvidia-smi --query-gpu=$GPU_GEN_STAT,$GPU_WIDTH_STAT,$LINK_MAX,$LINK_WIDTH_MAX,$GPU_GEN_MAX,$HOST_GEN_MAX --format=csv,noheader | tr -d ' ' )
  IFS=',' read -r GPU_G_C GPU_W_C GPU_G_CAP GPU_W_CAP GPU_G_M HOST_G_M <<< "$GPUINFO"

  if [[ $P_MODE == Enabled ]]; then
    echo -e "\nPersistence Mode is ${YELLOW}ENABLED${NC}."
    #echo "Momentarily disabling it to force pstate P0."
    #sudo nvidia-smi -pm 0 $>/dev/null
  else
    echo -e "\nPersistence Mode is ${GREEN}DISABLED${NC}."
  fi

  echo -e "Current pstate level: ${GREEN}"$P_STATE"${NC}"

  {
	  printf 'GPU Gen CURRENT\tGPU Width CURRENT\tGPU Gen CAPABLE\tGPU Width CAPABLE\tGPU Gen MAX\tHost Gen MAX\n';
	  printf "%s\n" ''$GPU_G_C'\t'$GPU_W_C'\t'$GPU_G_CAP'\t'$GPU_W_CAP'\t'$GPU_G_M'\t'$HOST_G_M'\n';
  } | ./extra/ptable 6 green

  echo -e "Your configured system is currently running at PCIe Gen ${GREEN}"$GPU_G_C"${NC}x${GREEN}"$GPU_W_C"${NC}."
  echo -e "Your configured system is capable of running at PCIe Gen ${GREEN}"$GPU_G_CAP"${NC}x${GREEN}"$GPU_W_CAP"${NC}."
  echo -e "Your GPU is able run at a max of PCIe Gen ${GREEN}"$GPU_G_M"${NC}."
  echo -e "Your machine can operate at a max of PCIe Gen ${GREEN}"$HOST_G_M"${NC}.\n"

#  if [[ $P_MODE == Enabled ]]; then
    #sudo nvidia-smi -pm 1 &>/dev/null
 # fi

#  if [[ $P_MODE == Disabled ]]; then
#    echo -e "\nPersistence Mode is ${GREEN}DISABLED${NC}.\n"
#    echo -e "\nYour GPU will automatically reduce its power state (including PCIe Gen and Width) when it's not being utilized."
#    echo -e "If your PCIe Link values are reporting lower than expected, you can override the power state by enabling ${GREEN}Persistence Mode${NC}."
#    echo -e "You can enable this by running ${YELLOW}'sudo nvidia-smi -pm 1'${NC}, and can be disabled by running ${YELLOW}'sudo nvidia-smi -pm 0'${NC}."
#    echo "After doing so, you can run this script again to see if your PCIe Link values show differently."
#    echo -e "\n${YELLOW}Note:${NC} Enabling Persistence Mode lowers driver latency at the cost of power, and heat."
#  else
#    echo -e "\nPersistence Mode is ${GREEN}ENABLED${NC}."
#  fi

}

function printInfo() {
  queryLink > $TMPOUT &
  _spinner
  # Clear loading bar
  echo -ne "\r"
  cat $TMPOUT
}

echo -n "Fetching data..."
printInfo
