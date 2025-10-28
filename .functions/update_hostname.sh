#!/usr/bin/env bash

################################################################################
# Script : update_hostname
#
# Objectif : Modifier le nom d'hôte du système (Ubuntu ou Alpine)
#
# Auteur : Alan MARCHAND (keltalan@proton.me)
#
# Compatibilité : Debian/Ubuntu, Alpine Linux 3.21 ou super
#
# Utilisation :
#   sudo ./update_hostname <nouveau_hostname>
#
# Aide :
# - Ce script doit être exécuté en tant que root.
# - Il vérifie si le nom d'hôte est déjà défini avant de le modifier.
# - Il détecte automatiquement le système (systemd ou BusyBox).
# - Il met à jour /etc/hostname et /etc/hosts si nécessaire.
################################################################################

NEW_HOSTNAME="$1"

# -----------------------------------------------------------------------------
# Chargement des fonctions utilitaires
# -----------------------------------------------------------------------------
COMMON_LIB="$HOME/alm-tools/lib/common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
  source "${COMMON_LIB}"
else
  echo "Fichier common.sh introuvable à ${COMMON_LIB}" >&2
  return 1
fi

# -----------------------------------------------------------------------------
# Vérification des droits
# -----------------------------------------------------------------------------
check_root

# -----------------------------------------------------------------------------
# Vérification de l'argument
# -----------------------------------------------------------------------------
if [ -z "$NEW_HOSTNAME" ]; then
  echo "[ERREUR] Aucun nom d'hôte fourni." >&2
  echo "Utilisation : sudo $0 <nouveau_hostname>"
  exit 1
fi

# -----------------------------------------------------------------------------
# Récupération du hostname actuel
# -----------------------------------------------------------------------------
if command -v hostnamectl &>/dev/null; then
  CURRENT_HOSTNAME=$(hostnamectl --static)
else
  CURRENT_HOSTNAME=$(hostname)
fi

# -----------------------------------------------------------------------------
# Comparaison
# -----------------------------------------------------------------------------
if [ "$NEW_HOSTNAME" = "$CURRENT_HOSTNAME" ]; then
  echo "[INFO] Le nom d'hôte est déjà défini sur '$CURRENT_HOSTNAME'. Aucun changement nécessaire."
  exit 0
fi

echo "[INFO] Changement du nom d'hôte : '$CURRENT_HOSTNAME' → '$NEW_HOSTNAME'"

# -----------------------------------------------------------------------------
# Détection du système
# -----------------------------------------------------------------------------
if command -v hostnamectl &>/dev/null; then
  # --- Méthode Ubuntu / systemd ---
  hostnamectl set-hostname "$NEW_HOSTNAME"
  echo "[INFO] hostnamectl utilisé pour définir le hostname."
else
  # --- Méthode Alpine / BusyBox ---
  echo "$NEW_HOSTNAME" > /etc/hostname
  hostname "$NEW_HOSTNAME"

  if grep -q "^127.0.0.1" /etc/hosts; then
    sed -i "s/^127.0.0.1.*/127.0.0.1   $NEW_HOSTNAME localhost/" /etc/hosts
  else
    echo "127.0.0.1   $NEW_HOSTNAME localhost" >> /etc/hosts
  fi
  echo "[INFO] /etc/hostname et /etc/hosts mis à jour."
fi

echo "[SUCCÈS] Nom d'hôte changé en : $NEW_HOSTNAME"

