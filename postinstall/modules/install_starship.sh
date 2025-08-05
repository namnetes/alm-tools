#!/usr/bin/env bash
################################################################################
# install_starship.sh
#
# Description :
# Ce module installe le prompt shell Starship globalement :
# - Vérifie la présence du binaire dans /usr/local/bin
# - Télécharge et exécute le script officiel d’installation
# - Ajoute la configuration dans les fichiers .bashrc / .zshrc des utilisateurs
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
# install_starship : Installe Starship prompt et configure les shells utilisateur
################################################################################
install_starship() {
  log_info "[INSTALLATION] Initialisation de Starship prompt."

  local starship_target="/usr/local/bin/starship"

  # 1. Vérification de présence
  if command -v starship &>/dev/null && [[ "$(command -v starship)" == "${starship_target}" ]]; then
    local starship_version
    starship_version=$(starship --version 2>&1 | cut -d ' ' -f2)
    log_info "  [STATUT] Starship déjà installé à ${starship_target} (version : ${starship_version})."
    return 0
  fi

  # 2. Téléchargement et exécution du script officiel
  log_info "  [ACTION] Téléchargement du script depuis https://starship.rs/install.sh..."
  local install_script
  install_script=$(mktemp)

  if ! curl -LsSf https://starship.rs/install.sh -o "${install_script}"; then
    log_error "Échec du téléchargement du script d’installation."
    rm -f "${install_script}"
    return 1
  fi

  log_info "  [ACTION] Exécution du script dans ${starship_target}..."
  #if ! STARSHIP_INSTALL_PATH="${starship_target}" bash "${install_script}" --yes; then
  if ! STARSHIP_INSTALL_PATH="${starship_target}" sh "${install_script}" --yes; then

    log_error "Échec de l’installation de Starship via le script officiel."
    rm -f "${install_script}"
    return 1
  fi

  chmod +x "${starship_target}"
  rm -f "${install_script}"

  # 3. Vérification finale
  if command -v starship &>/dev/null && [[ "$(command -v starship)" == "${starship_target}" ]]; then
    local final_version
    final_version=$(starship --version 2>&1 | cut -d ' ' -f2)
    log_info "[SUCCÈS] Starship installé avec succès (version : ${final_version})."
  else
    log_error "Starship semble mal installé ou non accessible dans ${starship_target}."
    return 1
  fi

  # 4. Configuration utilisateur
  log_info "[CONFIGURATION] Ajout de Starship dans les shells Bash/Zsh des utilisateurs existants..."

  local configured=false
  while IFS=: read -r user _ uid _ _ home shell; do
    if (( uid >= 1000 )) && [[ -d "${home}" ]] && [[ "${shell}" == */bash || "${shell}" == */zsh ]]; then
      local rc_file
      [[ "${shell}" == */bash ]] && rc_file="${home}/.bashrc"
      [[ "${shell}" == */zsh  ]] && rc_file="${home}/.zshrc"

      if [[ -f "${rc_file}" ]] && ! grep -q "starship init" "${rc_file}"; then
        echo -e "\n# Initialisation du prompt Starship\neval \"\$(starship init \$(basename \$SHELL))\"" >> "${rc_file}"
        chown "${user}:${user}" "${rc_file}"
        log_info "  [AJOUT] Configuration insérée dans ${rc_file} (utilisateur : ${user})."
        configured=true
      else
        log_info "  [STATUT] Configuration déjà présente ou fichier shell inexistant pour ${user}."
      fi
    fi
  done < /etc/passwd

  if [ "${configured}" = true ]; then
    log_info "  [NOTE] Les utilisateurs doivent recharger leur terminal ou sourcer leur shell (~/.bashrc ou ~/.zshrc)."
  else
    log_warn "  [ATTENTION] Aucun utilisateur configuré automatiquement. Configuration manuelle possible."
  fi

  log_info "[FIN] Installation et configuration de Starship terminées."
}
