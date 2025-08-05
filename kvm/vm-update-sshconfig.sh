#!/bin/bash

#==============================================================================
# Script Name   : vm_clone.sh
# Description   : This script verifies the existence of a specified VM, checks
#                 for an entry in the SSH configuration file ~/.ssh/config of
#                 the local user, and confirms that the VM is running. If all
#                 conditions are met, it updates only the IP address (HostName)
#                 and username (User) associated with the specified VM in the
#                 SSH configuration file.
# Author        : Alan MARCHAND
#==============================================================================

#==============================================================================
# Show help                                                                    #
#==============================================================================
show_help() {
  cat <<EOF
Usage: ${0##*/} [-h|--help] <VM_name>

Description:
This script verifies the existence of a specified VM, checks for an entry in 
the SSH configuration file ~/.ssh/config of the local user, and confirms that 
the VM is running. If all conditions are met, it updates only the IP address 
(HostName) and username (User) associated with the specified VM in the SSH 
configuration file.

Options:
  -h, --help         Display this help message and exit.

Parameters:
  <VM_name>          The name of the virtual machine to check and update.
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
    if [ -z "$VM_NAME" ]; then
      VM_NAME="$1"
    else
      echo "Unknown option: $1"
      show_help
      exit 1
    fi
    ;;
  esac
  shift
done

# Vérifie si le nom de VM a traité a été passé en paramètre
if [ -z "$VM_NAME" ]; then
  echo "Usage: ${0##*/} <nom_de_la_VM>"
  show_help
  exit 1
fi

VM_USER="galan"

# Vérifie que la VM existe dans la liste de virsh
if ! virsh list --all | grep -qw "$VM_NAME"; then
  echo "La VM $VM_NAME n'existe pas."
  exit 1
fi

# Vérifie si une entrée existe pour la VM dans ~/.ssh/config
SSH_CONFIG_PATH="$HOME/.ssh/config"
if ! grep -q "^Host $VM_NAME$" "$SSH_CONFIG_PATH"; then
  echo "Aucune entrée pour $VM_NAME dans $SSH_CONFIG_PATH."
  exit 1
fi

# Vérifie l'état de la VM
VM_STATE=$(virsh list --all | grep "$VM_NAME" | awk '{print $3}')

if [ "$VM_STATE" != "running" ]; then
  echo "La VM $VM_NAME n'est pas active."
  exit 1
fi

# Récupère l'adresse IP de la VM
VM_IP=$(virsh domifaddr "$VM_NAME" | grep -oP '(\d{1,3}\.){3}\d{1,3}')
echo $VM_IP

if [ -z "$VM_IP" ]; then
  echo "Impossible de récupérer l'IP de la VM $VM_NAME"
  exit 1
else
  echo "IP de la VM $VM_NAME : $VM_IP"
fi

# Mise à jour de la configuration SSH
sed -i "
# Trouver la section qui commence par 'Host $VM_NAME' et se termine par une 
# autre ligne Host
/^Host $VM_NAME$/,/^Host / {
  # Rechercher la ligne qui commence par 'HostName' et modifier son adresse IP
  s/^\( *HostName *\)\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\)/\1$VM_IP/
  # Rechercher la ligne qui commence par 'User' et modifier le nom 
  # d'utilisateur
  s/^\( *User *\)\(.*\)/\1$VM_USER/
}
" "$SSH_CONFIG_PATH"

echo "$HOME/.ssh/config updated."
