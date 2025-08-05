#!/bin/bash

#==============================================================================
# Script Name    : vm_manager.sh
# Description    : This script manages virtual machines by listing and 
#                  cloning them.
#
# Author         : Alan MARCHAND
#==============================================================================

#==============================================================================
# Show help                                                                    #
#==============================================================================
show_help() {
cat << EOF
Usage: ${0##*/} [-h|--help]

Description:
This script manages virtual machines by listing and cloning them.

Options:
  -h, --help         Display this help message and exit.

Parameters:
  The script does not take any positional parameters. It prompts the user for input during execution.
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

###############################################################################
# Function to list all VMs                                                    #
###############################################################################
list_vms() {
  echo "Available VMs:"
  echo "--------------"
  VM_INDEX=1
  VM_MAP=() # Declare VM_MAP as a global associative array
  for VM in $VM_LIST; do
    echo "$VM_INDEX) $VM"
    VM_MAP[$VM_INDEX]=$VM
    ((VM_INDEX++))
  done
  echo ""
}

###############################################################################
# Function to check the state of a VM                                         #
###############################################################################
check_vm_state() {
  local VM_STATE
  VM_STATE=$(virsh domstate "$VM_NAME")
  if [ "$VM_STATE" = "running" ]; then
    echo "The VM $VM_NAME is currently running."
    echo "Please stop it before cloning."
    exit 1
  fi
}

###############################################################################
# Function to check if the new VM name already exists                         #
###############################################################################
check_new_vm_name() {
  for existing_vm in "${VM_MAP[@]}"; do
    if [ "$existing_vm" = "$NEW_VM_NAME" ]; then
      echo "The new VM name already exists."
      echo "Please choose a different name."
      exit 1
    fi
  done
}

###############################################################################
# Function to clone the VM                                                    #
###############################################################################
clone_vm() {
  echo "Cloning $VM_NAME into a new VM named $NEW_VM_NAME..."

  virt-clone --original "$VM_NAME" --name "$NEW_VM_NAME" --auto-clone

  if [ $? -eq 0 ]; then
    NEW_VM_EXISTS=$(virsh list --all --name | grep -w "$NEW_VM_NAME")
    if [ "$NEW_VM_EXISTS" = "$NEW_VM_NAME" ]; then
      echo "Cloning of VM $VM_NAME to $NEW_VM_NAME was successful."
    else
      echo "Cloning failed or the new VM was not found."
      exit 1
    fi
  else
    echo "Cloning failed."
    exit 1
  fi
}

###############################################################################
# Script Execution                                                            #
###############################################################################

# List all VMs present
VM_LIST=$(virsh list --all --name)

# Check if the VM list is empty
if [ -z "$VM_LIST" ]; then
  echo "No VMs are present."
  exit 0
fi

# Display the VM menu
list_vms

# Ask the user to choose a VM to clone or exit
read -p "Which VM number to clone (Enter to quit)? : " VM_CHOICE

# If the user does not enter anything, exit the script
if [ -z "$VM_CHOICE" ]; then
  echo "Exiting script without action."
  exit 0
fi

# Check if the input is a valid number
if [[ ! $VM_CHOICE =~ ^[0-9]+$ ]] || [ -z "${VM_MAP[$VM_CHOICE]}" ]; then
  echo "Invalid VM number."
  exit 1
fi

# Get the name of the selected VM
VM_NAME=${VM_MAP[$VM_CHOICE]}
echo "You have chosen to clone the VM: $VM_NAME"

# Check if the VM to clone is running
check_vm_state

# Ask for the name of the new VM
read -p "Enter the name of the new VM to create: " NEW_VM_NAME

# If the user does not enter anything, exit the script
if [ -z "$NEW_VM_NAME" ]; then
  echo "Exiting script without creating a new VM."
  exit 0
fi

# Check if the new VM name already exists
check_new_vm_name

# Clone the VM
clone_vm

exit
