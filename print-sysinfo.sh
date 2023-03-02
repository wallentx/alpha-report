#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as sudo, or root."
  exit
fi

TMPOUT=$(mktemp /tmp/tmpXXXXXXXXXX)

function shutdown() {
  #tput cnorm
  rm "$TMPOUT"
}
trap shutdown EXIT

while getopts ":s" option; do
  case $option in
  s)
    SOURCED=true
    ;;
  \?)
    echo "Invalid option."
    exit
    ;;
  esac
done
shift "$((OPTIND - 1))"

source ./extra/spinner

function getInfo() {
  SYSNAME=$(hostname)
  OSNAME=$(hostnamectl | awk -F ': ' '/Operating System/ {print $2}')
  OSKERNEL=$(uname -r)
  VENDOR=($(hostnamectl | awk -F ': ' '/Hardware/ {print $2}'))
  CPUCOUNT=$(lscpu | awk '/Socket\(s\)/ {print $2"x"}')
  CPUMODEL=$(lscpu | grep '^Model name:' | awk -F: '{print $2}' | xargs)
  CPUCORES=$(lscpu | awk '/Core\(s\) per socket/ {print $4}')
  CPUTHREADS=$(lscpu | awk '/^CPU\(s\):/ {print $2}')
  GPUINFO=$(nvidia-smi --query-gpu=name,driver_version,pcie.link.gen.current,pcie.link.width.current --format=csv,noheader)
  IFS=',' read -r GPUNAME GPUDRIVER GPUPCIEGEN GPUPCIEWIDTH <<<"$GPUINFO"
  GPUQINFO=($(nvidia-smi -q | grep 'Board Part Number\|Product Architecture' | awk '{print $NF}'))
  IFS=' ' read -r GPUBOARD GPUARCH <<<"${GPUQINFO[*]}"
  MEMINFO=$(dmidecode -qt memory)
  MEMTOTAL=$(grep 'MemTotal' /proc/meminfo | awk '{print $2/1024/1024 "GB"}')
  MEMDIMMS=$(echo "$MEMINFO" | grep -i size | grep -v 'No' | awk '{ print $2$3}' | sort -rn | uniq -c | awk '{ printf("%dx%s", $1, $2) }')
  MEMTYPE=$(echo "$MEMINFO" | awk '/Memory Device/,/^$/ {if ($0 ~ /Type:/) {print $2}}' | uniq)
  MEMSPEED=$(echo "$MEMINFO" | grep "Speed:" | head -1 | awk '{ print $2 "MT/s" }')

  # System Name
  printf 'SYSTEM_NAME="%s"\n' "$SYSNAME"
  # OS
  printf 'OS="%s"\n' "${OSNAME#*: } $OSKERNEL"
  # System Vendor/Model
  echo -e "SYSVENDOR_MODEL=\"${VENDOR[*]}\""
  # CPU
  echo -e "CPU=\"$CPUCOUNT $CPUMODEL (C:$CPUCORES|T:$CPUTHREADS)\""
  # GPU Name
  printf 'GPU="%s"\n' "$GPUNAME"
  # GPU SKU
  printf 'GPU_SKU="%s"\n' "$GPUBOARD"
  # GPU Arch
  printf 'GPU_ARCH="%s"\n' "$GPUARCH"
  # NVIDIA Driver
  printf 'GPU_DRIVER="%s"\n' "${GPUDRIVER#" "}"
  # PCIe link
  printf 'PCIE_LINK="PCIe %sx%s"\n' "${GPUPCIEGEN#" "}" "${GPUPCIEWIDTH#" "}"
  # DRAM (Size, Type, MHz, etc)
  printf 'DRAM="%s"' "$MEMTOTAL, $MEMDIMMS $MEMTYPE, $MEMSPEED"
}

function printInfo() {
  getInfo >"$TMPOUT" &
  _spinner
  echo -ne "\r"
  cat "$TMPOUT"
}

if [[ $SOURCED == true ]]; then
  getInfo
else
  echo -n "Gathering system info..."
  printInfo
fi
