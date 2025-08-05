#!/bin/bash

#==============================================================================
# Script Name    : vm_get_ip.sh
# Description    : This script checks if a specified VM exists and verifies
#                  if it is running. If the VM is inactive, the script
#                  displays its inactive status and exits. If active, it
#                  retrieves and displays the VM's IP address, checks for an
#                  SSH configuration, and gives the user the option to initiate
#                  an SSH connection if a config is found.
# Author         : Alan MARCHAND
#==============================================================================

#==============================================================================
# Show help                                                                    #
#==============================================================================
show_help() {
  cat <<EOF
Usage: ${0##*/} [-h|--help] <VM_name>

Description:
This script checks if a specified VM exists and verifies if it is running. 
If the VM is inactive, the script displays its inactive status and exits. 
If active, it retrieves and displays the VM's IP address, checks for an SSH 
configuration, and gives the user the option to initiate an SSH connection 
if a config is found.

Options:
  -h, --help         Display this help message and exit.

Parameters:
  <VM_name>          The name of the virtual machine to check.
EOF
}

# Parse command-line options
VM_NAME=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    VM_NAME="$1"
    ;;
  esac
  shift
done

# Vérifie si le nom de la VM a été passé en paramètre
if [ -z "$VM_NAME" ]; then
  echo "Usage: ${0##*/} <nom_de_la_VM>"
  show_help
  exit 1
fi

# Nom de la VM à partir du paramètre
VM_NAME="$VM_NAME"

# Vérifier si la VM est active
VM_STATE=$(virsh list --all | grep "$VM_NAME" | awk '{print $3}')
if [ "$VM_STATE" != "running" ]; then
  echo "La VM $VM_NAME n'est pas active."
  exit 1
fi

# Récupérer l'IP de la VM
VM_IP=$(virsh domifaddr "$VM_NAME" | grep -oP '(\d{1,3}\.){3}\d{1,3}')
if [ -z "$VM_IP" ]; then
  echo "Impossible de récupérer l'IP de la VM $VM_NAME"
  exit 1
fi

# Afficher l'IP de la VM
echo "IP de la VM $VM_NAME : $VM_IP"

# Vérifier la présence de la configuration SSH pour la VM
if grep -q "Host $VM_NAME" ~/.ssh/config; then
  read -p "Souhaitez-vous vous connecter à la VM $VM_NAME via SSH ? (y/n) : " \
    RESPONSE
  if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
    echo "Connexion SSH à la VM $VM_NAME ($VM_IP)..."
    ssh "$VM_NAME"
  else
    echo "Adresse IP de la VM $VM_NAME : $VM_IP"
  fi
else
  echo "Aucune configuration SSH trouvée pour $VM_NAME dans ~/.ssh/config."
  echo "Adresse IP de la VM $VM_NAME : $VM_IP"
fi
