#!/usr/bin/env bash
set -e

C_COUNT=1000
while getopts "c:" opt; do
  case "$opt" in
    c)
      if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
        echo "Invalid argument for -c: $OPTARG is not an integer." >&2
        exit 1
      fi
      C_COUNT=${OPTARG}
      shift "$((OPTIND - 1))"
      ;;
    *)
      echo "Invalid option"
      exit 1
      ;;
  esac
done

PLOT=$1
PROC=$(nproc)

for ((i=1;i<=PROC;i++)); do
  if ((PROC % i == 0)); then
     bladebit_cuda -t "$i" simulate -n "$C_COUNT" -p $((PROC/i)) "$PLOT"
  fi
done
