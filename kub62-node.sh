#!/bin/bash

set -euo pipefail

usage() {
  local exit_code=${1:-1}

  cat <<EOF
Usage: $0 <shutdown|reboot>

Actions:
  shutdown       Drain the node and power it off
  reboot         Reboot the node without draining it first
  -h, --help     Show this help message

Notes:
  - shutdown uses 'kubectl drain', which already marks the node
    unschedulable before evicting pods.
  - A cordoned node stays unschedulable after reboot/shutdown until
    you run: kubectl uncordon <node>

Examples:
  $0 shutdown          # safe shutdown with drain + poweroff
  $0 reboot            # direct reboot without drain
EOF
  exit "$exit_code"
}

die() {
  echo "Error: $*" >&2
  exit 1
}

case "${1-}" in
  "") usage 1 ;;
  -h|--help) usage 0 ;;
esac

ACTION=$1
shift

if [[ $# -gt 0 ]]; then
  die "This script does not accept options. Use only: shutdown or reboot"
fi

case "$ACTION" in
  shutdown)
    node=$(hostname -s)

    if ! kubectl get node "$node" >/dev/null 2>&1; then
      die "Kubernetes node '$node' was not found in the current kubeconfig context"
    fi

    echo "Draining current node ($node)..."
    kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data
    echo "Powering off current node ($node)..."
    sudo systemctl poweroff
    ;;
  reboot)
    echo "Rebooting current node..."
    sudo systemctl reboot
    ;;
  *)
    die "Unknown action: $ACTION"
    ;;
esac

