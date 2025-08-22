#!/usr/bin/env bash
################################################################################
# install_github_cli.sh
#
# Description :
# Ce module installe GitHub CLI (gh) depuis le dépôt officiel :
# - Vérifie si GitHub CLI est déjà installé
# - Installe wget si nécessaire
# - Ajoute la clé GPG et le dépôt officiel à APT
# - Met à jour les paquets et installe gh
#
# Auteur : Magali + Copilot
#
# Usage :
# Ce script doit être sourcé depuis un script principal.
################################################################################

# -----------------------------------------------------------------------------
# Vérification : ce module doit être sourcé, pas exécuté directement
# -----------------------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
  echo "Ce script doit être sourcé, pas exécuté directement." >&2
  return 1 2>/dev/null || exit 1
}

################################################################################
# install_github_cli : Installe GitHub CLI pour l'utilisateur root
################################################################################
install_githubcli() {
  log_info "[INSTALLATION] Initialisation de GitHub CLI (gh)."

  local gh_bin
  gh_bin=$(command -v gh 2>/dev/null)

  # 1. Vérification de présence
  if [[ -n "${gh_bin}" ]]; then
    local gh_version
    gh_version=$(gh --version 2>&1 | head -n 1 | awk '{print $3}')
    log_info "  [STATUT] GitHub CLI déjà installé (version : ${gh_version})."
    return 0
  fi

  # 2. Vérification de wget
  log_info "  [VERIFICATION] Présence de wget..."
  if ! type -p wget >/dev/null; then
    log_info "  [ACTION] wget non présent, tentative d'installation..."
    if ! apt-get install -y wget; then
      log_error "  Échec de l'installation de wget. Abandon."
      return 1
    fi
  fi

  # 3. Ajout de la clé GPG du dépôt GitHub CLI
  log_info "  [ACTION] Ajout de la clé GPG..."
  local keyring_dir="/etc/apt/keyrings"
  mkdir -p -m 755 "${keyring_dir}"

  local temp_gpg
  temp_gpg=$(mktemp)
  if ! wget -nv -O "${temp_gpg}" https://cli.github.com/packages/githubcli-archive-keyring.gpg; then
    log_error "  Échec du téléchargement de la clé GPG."
    rm -f "${temp_gpg}"
    return 1
  fi

  if ! cat "${temp_gpg}" | tee "${keyring_dir}/githubcli-archive-keyring.gpg" > /dev/null; then
    log_error "  Impossible d'ajouter la clé au trousseau."
    rm -f "${temp_gpg}"
    return 1
  fi
  rm -f "${temp_gpg}"
  chmod go+r "${keyring_dir}/githubcli-archive-keyring.gpg"

  # 4. Ajout du dépôt APT
  log_info "  [ACTION] Ajout du dépôt GitHub CLI..."
  mkdir -p -m 755 /etc/apt/sources.list.d
  local arch
  arch=$(dpkg --print-architecture)
  echo "deb [arch=${arch} signed-by=${keyring_dir}/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

  # 5. Mise à jour APT
  log_info "  [ACTION] Mise à jour des paquets..."
  if ! apt-get update; then
    log_error "  Échec de la mise à jour APT."
    return 1
  fi

  # 6. Installation de gh
  log_info "  [ACTION] Installation de GitHub CLI..."
  if ! apt-get install gh -y; then
    log_error "  Échec de l'installation de GitHub CLI."
    return 1
  fi

  # 7. Vérification finale
  if command -v gh >/dev/null; then
    local final_version
    final_version=$(gh --version 2>&1 | head -n 1 | awk '{print $3}')
    log_info "[SUCCÈS] GitHub CLI installé avec succès (version : ${final_version})."
  else
    log_error "GitHub CLI semble mal installé ou introuvable dans le PATH."
    return 1
  fi
}
