#!/usr/bin/env bash
################################################################################
# install_uv.sh
#
# Description :
# Ce module installe le gestionnaire de paquets Python `uv` :
# - Vérifie la présence de Python 3, pip3 et le module venv
# - Télécharge et exécute le script officiel d’installation de uv
# - S’assure que uv est installé dans ~/.local/bin pour l’utilisateur original
#
# Auteur : Alan MARCHAND (galan.marchand@outlook.fr)
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
# install_uv : Installe le gestionnaire de paquets Python uv pour l’utilisateur
################################################################################
install_uv() {
  log_info "[INSTALLATION] Initialisation de uv packager."

  local original_user="${SUDO_USER}"
  local original_user_home
  original_user_home=$(getent passwd "${original_user}" | cut -d: -f6)

  if [ -z "${original_user_home}" ]; then
    log_error "Impossible de déterminer le répertoire personnel de ${original_user}."
    return 1
  fi

  local uv_bin="${original_user_home}/.local/bin/uv"

  # 1. Vérification de Python 3
  if command -v python3 &>/dev/null; then
    local PYTHON3_CURRENT_VERSION
    PYTHON3_CURRENT_VERSION=$(python3 --version 2>&1 | cut -d ' ' -f2)
    log_info "  [STATUT] Python 3 détecté (version : ${PYTHON3_CURRENT_VERSION})."
  else
    log_error "Python 3 est requis mais n'a pas été détecté."
    log_error "L'installation de uv ne peut pas continuer."
    return 1
  fi

  # 2. Vérification de pip3
  if command -v pip3 &>/dev/null; then
    log_info "  [STATUT] pip3 est présent."
  else
    log_warn "pip3 n'est pas installé mais il n'est pas requis."
  fi

  # 3. Vérification du module venv
  if python3 -c "import venv" &>/dev/null; then
    log_info "  [STATUT] Le module 'venv' est disponible."
  else
    log_warn "'venv' est recommandé mais non disponible pour Python 3."
    log_error "Ce module ne gère l'installation de python-venv."
    log_error "L'installation de uv ne peut pas continuer."
    return 1
  fi

  # Installation de uv si non présent
  if [ ! -f "${uv_bin}" ]; then
    log_info "[ACTION] uv n’est pas présent à ${uv_bin}. Installation via script officiel..."

    local install_script
    install_script=$(mktemp)

    if ! curl -LsSf https://astral.sh/uv/install.sh -o "${install_script}"; then
      log_error "Échec du téléchargement du script uv."
      rm -f "${install_script}"
      return 1
    fi

    chown "${original_user}:${original_user}" "${install_script}"
    chmod u+x "${install_script}"

    mkdir -p "${original_user_home}/.local/bin"
    chown "${original_user}:${original_user}" "${original_user_home}/.local/bin"

    if ! sudo -u "${original_user}" HOME="${original_user_home}" bash "${install_script}"; then
      log_error "Échec de l’installation de uv en tant que ${original_user}."
      rm -f "${install_script}"
      return 1
    fi

    rm -f "${install_script}"
  else
    log_info "[STATUT] uv est déjà présent à ${uv_bin}."
  fi

  # Vérification finale
  if [ -x "${uv_bin}" ]; then
    log_info "[SUCCÈS] uv est installé et exécutable à ${uv_bin}."
    log_info "[NOTE] Vérifiez que ~/.local/bin est bien dans le PATH de ${original_user}."
  else
    log_error "uv semble mal installé. Aucune exécutable trouvé à ${uv_bin}."
    return 1
  fi
}
