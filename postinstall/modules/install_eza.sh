#!/usr/bin/env bash
################################################################################
# install_eza.sh
#
# Description :
# Ce module installe l’outil EZA (alternative moderne à ls) sur Ubuntu/Debian :
# - Vérifie si EZA est déjà installé
# - Configure le dépôt officiel maintenu par gierens.de
# - Installe EZA via apt
# - Valide l’installation
#
# Auteur : Alan MARCHAND (keltalan@proton.me)
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
# install_eza : Installe EZA via dépôt officiel
################################################################################
install_eza() {
  log_info "[INSTALLATION] Initialisation de EZA."

  local eza_bin
  eza_bin=$(command -v eza 2>/dev/null)

  # 1. Vérification de présence
  if [[ -n "${eza_bin}" ]]; then
    local eza_version
    eza_version=$("${eza_bin}" --version 2>&1 | head -n 1)
    log_info "  [STATUT] EZA déjà installé (${eza_version})."
    return 0
  fi

  # 2. Ajout du dépôt officiel
  log_info "  [ACTION] Configuration du dépôt gierens.de..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | \
    sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg

  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | \
    sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null

  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

  # 3. Mise à jour et installation
  log_info "  [ACTION] Mise à jour des paquets et installation de EZA..."
  sudo apt update
  sudo apt install -y eza

  # 4. Vérification finale
  if command -v eza &>/dev/null; then
    local final_version
    final_version=$(eza --version 2>&1 | head -n 1)
    log_info "[SUCCÈS] EZA installé avec succès (${final_version})."
  else
    log_error "EZA semble mal installé ou introuvable dans le PATH."
    return 1
  fi
}
