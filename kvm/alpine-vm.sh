#!/bin/bash

# =====================================================================
# Script de création d'une VM Alpine Linux sous KVM
# Auteur : Alan - Date : $(date +"%Y-%m-%d")
# Description :
# Automatisation du déploiement d'une VM Alpine Linux via libvirt/KVM.
# Gère le téléchargement de l'ISO, la configuration du disque et la VM.
# =====================================================================

# === Configuration ===
VERSION=${VERSION:-"3.21"}     # Version d'Alpine Linux
RELEASE=${RELEASE:-"3"}        # Numéro de release spécifique
DISK_SIZE="10G"                # Taille du disque virtuel
VM_NAME="Alpine-Linux-$VERSION.$RELEASE"

ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v$VERSION/releases/x86_64/alpine-virt-$VERSION.$RELEASE-x86_64.iso"

ISO_PATH="$HOME/.local/share/libvirt/images/alpine-virt-$VERSION.$RELEASE-x86_64.iso"

DISK_PATH="$HOME/.local/share/libvirt/qcow2/alpine-linux-$VERSION-$RELEASE.qcow2"

XML_FILE="./alpine-vm.xml"

# === Vérification des dépendances ===
REQUIRED_CMDS=("wget" "qemu-img" "virsh")

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo "Erreur : $cmd n'est pas installé. Veuillez l'ajouter."
        exit 1
    fi
done

# === Vérification du fichier XML ===
if [ ! -f "$XML_FILE" ]; then
    echo "Erreur : Le fichier $XML_FILE est introuvable."
    exit 1
fi

echo "Le fichier XML de configuration est présent."

# === Création des répertoires ===
mkdir -p "$(dirname "$ISO_PATH")"
mkdir -p "$(dirname "$DISK_PATH")"

# === Téléchargement de l'ISO ===
if [ ! -f "$ISO_PATH" ]; then
    echo "Téléchargement de l'ISO Alpine Linux v$VERSION.$RELEASE..."
    wget -q -O "$ISO_PATH" "$ISO_URL" || { 
        echo "Erreur : Échec du téléchargement."; exit 1; 
    }
else
    echo "L'image ISO existe déjà, téléchargement inutile."
fi

# === Suppression de l'ancienne VM ===
if virsh list --all | grep -q "$VM_NAME"; then
    echo "Une VM avec le nom $VM_NAME existe déjà. Suppression en cours..."
    virsh destroy "$VM_NAME" &>/dev/null
    virsh undefine "$VM_NAME" --remove-all-storage
    echo "Ancienne VM supprimée."
fi

# === Création du disque virtuel ===
if [ ! -f "$DISK_PATH" ]; then
    echo "Création du disque virtuel ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_PATH" "$DISK_SIZE" || {
        echo "Erreur : Échec de la création du disque."; exit 1;
    }
else
    echo "Le disque virtuel existe déjà."
fi

# === Définition et démarrage de la VM ===
echo "Définition et démarrage de la VM avec libvirt..."
virsh define "$XML_FILE" || {
    echo "Erreur : Échec de la définition de la VM."; exit 1;
}

echo "Installation terminée pour Alpine Linux v$VERSION.$RELEASE !"

