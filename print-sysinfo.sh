#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
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
  VENDOR=($(hostnamectl | grep 'Hardware' | sed 's/.*: //g'))
  CPUCOUNT=$(lscpu | grep 'Socket(s):' | awk -F: '{print $2}' | xargs)
  CPUMODEL=$(lscpu | grep '^Model name:' | awk -F: '{print $2}' | xargs)
  CPUCORES=$(lscpu | grep 'Core(s) per socket:' | awk -F: '{print $2}' | xargs)
  CPUTHREADS=$(lscpu | grep '^CPU(s)' | awk -F: '{print $2}' | xargs)
  GPUNAME=$(nvidia-smi --query-gpu=name --format=csv,noheader)
  GPUDRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)
  GPUPCIEGEN=$(nvidia-smi --query-gpu=pcie.link.gen.current --format=csv,noheader)
  GPUPCIEWIDTH=$(nvidia-smi --query-gpu=pcie.link.width.current --format=csv,noheader)
  MEMTOTAL=$(grep 'MemTotal' /proc/meminfo | awk '{print $2/1024/1024 "GB"}')
  MEMDIMMS=$(dmidecode -t memory | grep -i size | grep -v 'No' | awk '{ print $2$3}' | sort -rn | uniq -c | awk '{ printf("%dx%s", $1, $2) }')
  MEMSPEED=$(dmidecode -t memory | grep "Speed:" | head -1 | awk '{ print $2 "MT/s" }')

  # Clear loading bar
  echo -ne "\r"
  # System Name
  echo -e "SystemName=\"$SYSNAME\""
  # OS
  echo -e "OS=\"${OSNAME#*: } $OSKERNEL\""
  # System Vendor/Model
  echo -e "SystemVendor/Model=\"${VENDOR[*]}\""
  # CPU
  echo -e 'CPU="'$CPUCOUNT"x $CPUMODEL (C:$CPUCORES|T:$CPUTHREADS)\""
  # GPU
  echo -e "GPU=\"$GPUNAME\""
  # NVIDIA Driver
  echo -e "DriverVersion=\"$GPUDRIVER\""
  # PCIe link
  echo -e 'PCIeLink="PCIe '$GPUPCIEGEN"x"$GPUPCIEWIDTH"\""
  # DRAM (Size, Type, MHz, etc)
  echo -e "DRAM=\"$MEMTOTAL, $MEMDIMMS, $MEMSPEED\""
}

function printInfo() {
  getInfo >$TMPOUT &
  spinner
  cat $TMPOUT
}

echo -n "Gathering system info..."
printInfo
