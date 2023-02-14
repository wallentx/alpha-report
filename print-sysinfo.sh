#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as sudo, or root."
  exit
fi

TMPOUT=$(mktemp /tmp/tmpXXXXXXXXXX)

function shutdown() {
  tput cnorm
  rm $TMPOUT
}
trap shutdown EXIT

function cursorBack() {
  echo -en "\033[$1D"
}

function spinner() {
  local LC_CTYPE=C
  local LC_ALL=en_US.utf-8
  tput civis
  local CL="\e[2K"
  local spin="⣷⣯⣟⡿⢿⣻⣽⣾"
  local pid=$(jobs -p)
  local charwidth=1
  while kill -0 $pid 2>/dev/null; do
    local i=$(((i + charwidth) % ${#spin}))
    printf "%s" "$(tput setaf 2)${spin:i:charwidth}$(tput sgr0)"
    cursorBack 1
    sleep .1
  done
  printf "${CL}"
  tput cnorm
  wait $(jobs -p)
}

function getInfo() {
  SYSNAME=$(hostname)
  OSNAME=$(hostnamectl | awk -F ': ' '/Operating System/ {print $2}')
  OSKERNEL=$(uname -r)
  VENDOR=($(hostnamectl | awk -F ': ' '/Hardware/ {print $2}'))
  CPUCOUNT=$(lscpu | awk '/Socket\(s\)/ {print $2"x"}')
  CPUMODEL=$(lscpu | grep '^Model name:' | awk -F: '{print $2}' | xargs)
  CPUCORES=$(lscpu | awk '/Core\(s\) per socket/ {print $4}')
  CPUTHREADS=$(lscpu | awk '/^CPU\(s\)/ {print $2}')
  GPUINFO=$(nvidia-smi --query-gpu=name,driver_version,pcie.link.gen.current,pcie.link.width.current --format=csv,noheader)
  IFS=',' read -r GPUNAME GPUDRIVER GPUPCIEGEN GPUPCIEWIDTH <<< "$GPUINFO"
  GPUQINFO=( $(nvidia-smi -q | grep 'Board Part Number\|Product Architecture' | awk '{print $NF}') )
  IFS=' ' read -r GPUBOARD GPUARCH <<< "${GPUQINFO[*]}"
  MEMINFO=$(dmidecode -t memory)
  MEMTOTAL=$(grep 'MemTotal' /proc/meminfo | awk '{print $2/1024/1024 "GB"}')
  MEMDIMMS=$(echo "$MEMINFO" | grep -i size | grep -v 'No' | awk '{ print $2$3}' | sort -rn | uniq -c | awk '{ printf("%dx%s", $1, $2) }')
  MEMTYPE=$(echo "$MEMINFO" | awk '/Memory Device/,/^$/ {if ($0 ~ /Type:/) {print $2}}' | uniq)
  MEMSPEED=$(echo "$MEMINFO" | grep "Speed:" | head -1 | awk '{ print $2 "MT/s" }')

  # Clear loading bar
  echo -ne "\r"
  # System Name
  echo -e "SystemName=\"$SYSNAME\""
  # OS
  echo -e "OS=\"${OSNAME#*: } $OSKERNEL\""
  # System Vendor/Model
  echo -e "SystemVendor/Model=\"${VENDOR[*]}\""
  # CPU
  echo -e "CPU=\"$CPUCOUNT $CPUMODEL (C:$CPUCORES|T:$CPUTHREADS)\""
  # GPU Name
  printf 'GPU="%s"\n' "$GPUNAME"
  # GPU SKU
  printf 'GPUSKU="%s"\n' "$GPUBOARD"
  # GPU Arch
  printf 'GPUArch="%s"\n' "$GPUARCH"
  # NVIDIA Driver
  printf 'DriverVersion="%s"\n' "${GPUDRIVER#" "}"
  # PCIe link
  printf 'PCIeLink="PCIe %sx%s"\n' "${GPUPCIEGEN#" "}" "${GPUPCIEWIDTH#" "}"
  # DRAM (Size, Type, MHz, etc)
  echo -e "DRAM=\"$MEMTOTAL, $MEMDIMMS $MEMTYPE, $MEMSPEED\""
}

function printInfo() {
  getInfo >$TMPOUT &
  spinner
  cat $TMPOUT
}

echo -n "Gathering system info..."
printInfo
