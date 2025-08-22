#!/usr/bin/env bash

#
# Description :
# Ce script installe le navigateur web Brave sur une distribution
# compatible Debian/Ubuntu en ajoutant son dépôt officiel.
#
# Le processus comprend :
# - L'ajout de la clé de signature GPG de Brave.
# - L'ajout du dépôt apt-get de Brave aux sources du système.
# - La mise à jour des paquets et l'installation de Brave.
#
# Auteur : Alan MARCHAND

# -----------------------------------------------------------------------------
# Vérification : ce module doit être sourcé, pas exécuté directement
# -----------------------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
  echo "Ce script doit être sourcé, pas exécuté directement." >&2
  return 1 2>/dev/null || exit 1
}

# -----------------------------------------------------------------------------
# Fonction principale pour l'installation de Brave
# -----------------------------------------------------------------------------
install_brave() {
  log_info "Initialisation de l'installation du navigateur Brave."

  # 1. Vérification de la présence de Brave
  if command -v brave-browser &>/dev/null; then
    local brave_version
    brave_version=$(brave-browser --version | awk '{print $NF}' | cut -d'/' -f2)
    log_info "Brave est déjà installé (version : ${brave_version}). Aucune action requise."
    return 0
  fi

  # 4. Ajout de la clé GPG
  log_info "Ajout de la clé GPG de Brave..."
  local key_ring_path="/etc/apt/keyrings/brave-browser-archive-keyring.gpg"
  local key_url="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

  if ! sudo mkdir -p /etc/apt/keyrings &>/dev/null; then
    log_error "Échec de la création du répertoire pour les clés GPG."
    return 1
  fi

  if ! curl -fsSLo "${key_ring_path}" "${key_url}"; then
    log_error "Échec du téléchargement de la clé GPG de Brave."
    return 1
  fi

  # 5. Ajout du dépôt APT
  log_info "Ajout du dépôt Brave aux sources APT..."
  local source_list_file="/etc/apt/sources.list.d/brave-browser-release.list"
  local repo_entry="deb [signed-by=${key_ring_path}] https://brave-browser-apt-release.s3.brave.com/ stable main"

  if ! echo "${repo_entry}" | sudo tee "${source_list_file}" &>/dev/null; then
    log_error "Échec de l'ajout du dépôt Brave."
    return 1
  fi

  # 6. Mise à jour des dépôts
  log_info "Mise à jour de la liste des paquets avec le nouveau dépôt..."
  if ! sudo apt-get update &>/dev/null; then
    log_error "Échec de la mise à jour des paquets après l'ajout du dépôt Brave."
    return 1
  fi

  # 7. Installation de Brave
  log_info "Installation du paquet brave-browser..."
  if ! sudo apt-get install -y brave-browser &>/dev/null; then
    log_error "Échec de l'installation de Brave."
    return 1
  fi

  # 8. Vérification finale
  if command -v brave-browser &>/dev/null; then
    local final_version
    final_version=$(brave-browser --version | awk '{print $NF}' | cut -d'/' -f2)
    log_info "Brave a été installé avec succès (version : ${final_version})."
    return 0
  else
    log_error "Installation de Brave échouée. Le binaire 'brave-browser' est introuvable."
    return 1
  fi
}
