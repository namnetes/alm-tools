#!/bin/bash

#==============================================================================
# Script Name    : list_vms.sh
# Description    : This script lists all existing virtual machines along 
#                  with their current status.
# Author         : Alan MARCHAND
#==============================================================================

#==============================================================================
# Show help                                                                    #
#==============================================================================
show_help() {
cat << EOF
Usage: ${0##*/} [-h|--help]

Description:
This script lists all existing virtual machines along with their current status.

Options:
  -h, --help         Display this help message and exit.

Parameters:
  The script does not take any positional parameters.
EOF
}

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Vérifie si virsh est installé
if ! command -v virsh &> /dev/null; then
    echo "Error: virsh is not installed. Please install it first."
    exit 1
fi

# Liste toutes les VMs et leur état
echo "Listing all existing virtual machines and their status..."
echo "----------------------------------------------------------"
printf "%-30s %-10s\n" "VM Name" "Status"
echo "----------------------------------------------------------"

# Récupère la liste des VMs avec leur état
virsh list --all --name | while read -r vm_name; do
    vm_state=$(virsh domstate "$vm_name" 2>/dev/null)
    printf "%-30s %-10s\n" "$vm_name" "$vm_state"
done
