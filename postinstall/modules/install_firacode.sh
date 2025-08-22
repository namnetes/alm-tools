#!/usr/bin/env bash
################################################################################
# install_fira_code_nerd_font.sh
#
# Description :
# Ce module installe la police Fira Code Nerd Font sur le système :
# - Vérifie si la police est déjà installée (via fichier ou fontconfig)
# - Télécharge l’archive depuis GitHub
# - Décompresse et installe les fichiers pour tous les utilisateurs
# - Met à jour le cache des polices et valide l'installation
#
# La police est installée pour tous les utilisateurs via /usr/local/share/fonts.
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
# install_fira_code_nerd_font : Installe Fira Code Nerd Font pour tous
################################################################################
install_firacode() {
  log_info "[INSTALLATION] Initialisation de Fira Code Nerd Font."

  local font_name="FiraCode Nerd Font"
  local install_path="/usr/local/share/fonts/FiraCodeNerdFont"
  local sample_file="${install_path}/FiraCodeNerdFont-Regular.ttf"

  # 1. Vérification de présence
  if [[ -f "${sample_file}" ]] || fc-list | grep -q "${font_name}" || fc-match "${font_name}" | grep -q "FiraCode"; then
    log_info "  [STATUT] ${font_name} déjà installée et détectée."
    return 0
  fi

  # 2. Téléchargement de l’archive
  local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
  local temp_dir
  temp_dir=$(mktemp -d)
  local font_zip="${temp_dir}/FiraCode.zip"

  log_info "  [ACTION] Téléchargement depuis : ${download_url}"
  if ! curl -Ls "${download_url}" -o "${font_zip}"; then
    log_error "Échec du téléchargement de Fira Code Nerd Font."
    rm -rf "${temp_dir}"
    return 1
  fi

  # 3. Décompression
  log_info "  [ACTION] Décompression dans : ${temp_dir}"
  if ! command -v unzip &>/dev/null; then
    log_error "'unzip' est requis mais non installé. Veuillez l'installer."
    rm -rf "${temp_dir}"
    return 1
  fi
  if ! unzip -o "${font_zip}" -d "${temp_dir}"; then
    log_error "Échec de la décompression."
    rm -rf "${temp_dir}"
    return 1
  fi

  # 4. Installation dans /usr/local/share/fonts
  log_info "  [ACTION] Installation des fichiers dans : ${install_path}"
  mkdir -p "${install_path}"
  if ! find "${temp_dir}" -iname '*.ttf' -exec cp {} "${install_path}/" \;; then
    log_error "Échec de la copie des polices."
    rm -rf "${temp_dir}"
    return 1
  fi
  chmod 644 "${install_path}"/*

  # 5. Nettoyage
  rm -rf "${temp_dir}"

  # 6. Mise à jour du cache des polices
  log_info "  [ACTION] Mise à jour du cache avec fc-cache..."
  if ! fc-cache -fv; then
    log_error "Échec de la mise à jour du cache."
    return 1
  fi

  # 7. Vérification finale
  if fc-list | grep -q "${font_name}"; then
    log_info "[SUCCÈS] ${font_name} installée avec succès."
  else
    log_error "Police installée mais non détectée après mise à jour."
    return 1
  fi
}
