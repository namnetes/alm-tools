#!/usr/bin/env bash
################################################################################
# install_xan.sh
#
# Description :
# Ce module installe l’outil Xan CSV Magician depuis GitHub :
# - Vérifie si Xan est déjà installé dans /usr/local/bin
# - Récupère la dernière version depuis l’API GitHub
# - Télécharge et extrait le binaire depuis l’archive tar.gz
# - Nettoie le fichier temporaire et valide l’installation
#
# Auteur : Alan MARCHAND
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
# install_xan : Installe Xan CSV Magician pour l'utilisateur root
################################################################################
install_xan() {
  log_info "[INSTALLATION] Initialisation de Xan CSV Magician."

  local xan_target="/usr/local/bin/xan"
  local xan_bin
  xan_bin=$(command -v xan 2>/dev/null)

  # 1. Vérification de présence
  if [[ "${xan_bin}" == "${xan_target}" ]]; then
    local xan_version
    xan_version=$(xan --version 2>&1 | head -n 1 | awk '{print $NF}')
    log_info "  [STATUT] Xan déjà installé à ${xan_target} (version : ${xan_version})."
    return 0
  fi

  # 2. Récupération de la dernière version via GitHub API
  log_info "  [ACTION] Récupération de la dernière version depuis GitHub..."
  local XAN_VERSION
  XAN_VERSION=$(curl -s https://api.github.com/repos/medialab/xan/releases/latest | grep -Po '"tag_name": "\K[0-9.]+' )

  if [ -z "${XAN_VERSION}" ]; then
    log_error "Impossible de récupérer la version Xan depuis GitHub."
    return 1
  fi
  log_info "  [INFO] Version la plus récente : ${XAN_VERSION}"

  # 3. Téléchargement de l’archive
  local download_url="https://github.com/medialab/xan/releases/download/${XAN_VERSION}/xan-x86_64-unknown-linux-gnu.tar.gz"
  local temp_tar
  temp_tar=$(mktemp --suffix=.tar.gz)

  log_info "  [ACTION] Téléchargement depuis : ${download_url}"
  if ! curl -Ls "${download_url}" -o "${temp_tar}"; then
    log_error "Échec du téléchargement depuis GitHub."
    rm -f "${temp_tar}"
    return 1
  fi

  # 4. Extraction vers /usr/local/bin
  log_info "  [ACTION] Extraction du binaire vers ${xan_target}"
  if ! tar xf "${temp_tar}" -C "$(dirname "${xan_target}")" xan; then
    log_error "Échec de l’extraction du binaire xan."
    rm -f "${temp_tar}"
    return 1
  fi
  chmod +x "${xan_target}"

  # 5. Nettoyage
  rm -f "${temp_tar}"

  # 6. Vérification finale
  if command -v xan &>/dev/null && [[ "$(command -v xan)" == "${xan_target}" ]]; then
    local final_version
    final_version=$(xan --version 2>&1 | head -n 1 | awk '{print $NF}')
    log_info "[SUCCÈS] Xan installé avec succès (version : ${final_version})."
  else
    log_error "Xan semble mal installé ou introuvable dans le PATH."
    return 1
  fi
}
