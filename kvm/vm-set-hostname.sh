#!/bin/bash

#==============================================================================
# Script Name    : change_hostname.sh
# Description    : This script checks if a specified VM exists and verifies 
#                  if it is running. If inactive, displays its status and exits.
#                  If active, retrieves the hostname of the VM via SSH and
#                  prompts the user for a new hostname.
#                  Prerequisite: SSH key authentication and sudo privileges
#                  without password prompt for hostname update.
# Author         : Alan MARCHAND
#==============================================================================

#==============================================================================
# Show help                                                                    #
#==============================================================================
show_help() {
cat << EOF
Usage: ${0##*/} [-h|--help] <VM_name>

Description:
This script checks if a specified VM exists and verifies if it is running. 
If inactive, displays its status and exits. If active, retrieves the hostname 
of the VM via SSH and prompts the user for a new hostname. 

Prerequisite: SSH key authentication and sudo privileges without password 
prompt for hostname update.

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
        -h|--help)
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

# Vérifie si le nom de la VM a été passé en paramètre
if [ -z "$VM_NAME" ]; then
    echo "Usage: ${0##*/} <nom_de_la_VM>"
    show_help
    exit 1
fi

# Vérifier si la VM existe
VM_EXISTS=$(virsh list --all | grep "$VM_NAME")

if [ -z "$VM_EXISTS" ]; then
    echo "La VM $VM_NAME n'existe pas."
    exit 1
fi

# Vérifier si la VM est active
VM_STATE=$(echo "$VM_EXISTS" | awk '{print $3}')

if [ "$VM_STATE" != "running" ]; then
    echo "La VM $VM_NAME n'est pas active."
    exit 1
fi

# Vérifier si la configuration SSH existe dans ~/.ssh/config
SSH_CONFIG=~/.ssh/config

# Récupérer le chemin de la clé privée associé à l'entrée Host pour la VM
KEY_FILE=$(awk -v host="$VM_NAME" '
    $1 == "Host" && $2 == host {
        found = 1
    }
    found && $1 == "IdentityFile" {
        print $2
        exit
    }
' "$SSH_CONFIG")

# Utiliser eval pour développer le chemin du fichier de clé
KEY_FILE=$(eval echo "$KEY_FILE")

if [ -z "$KEY_FILE" ]; then
    echo "Aucune clé privée spécifiée pour la VM $VM_NAME dans ~/.ssh/config."
    exit 1
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "Le fichier de clé SSH $KEY_FILE n'existe pas."
    exit 1
fi

# Récupérer le hostname de la VM via SSH
CURRENT_HOSTNAME=$(ssh "$VM_NAME" hostname 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Impossible de se connecter à la VM $VM_NAME pour récupérer le hostname."
    exit 1
fi

echo "Hostname actuel de la VM $VM_NAME : $CURRENT_HOSTNAME"

# Demander à l'utilisateur le nouveau hostname
read -p "Entrez le nouveau hostname pour la VM $VM_NAME : " NEW_HOSTNAME

if [ -z "$NEW_HOSTNAME" ]; then
    echo "Aucun nouveau hostname n'a été fourni. Le changement est annulé."
    exit 1
fi

# Changer le hostname avec sudo -S pour éviter le besoin d'un terminal
ssh -t "$VM_NAME" << EOF
echo "$NEW_HOSTNAME" | sudo -S tee /etc/hostname > /dev/null
sudo hostname "$NEW_HOSTNAME"
EOF

# Vérification de l'opération
if [ $? -eq 0 ]; then
    echo "Hostname changé avec succès pour la VM $VM_NAME."
else
    echo "Une erreur s'est produite lors du changement de hostname."
fi

