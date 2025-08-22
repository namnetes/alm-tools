#!/usr/bin/env bash
################################################################################
# install_core_packages.sh
#
# Description :
# Ce module installe les paquets essentiels via APT :
# - Lit les noms de paquets depuis config/packages_to_install.list
# - Ignore les lignes vides ou commentées
# - Installe uniquement les paquets absents du système
# Toutes les opérations sont idempotentes et pilotées par configuration.
#
# Auteur : Alan MARCHAND
#
# Usage :
# Ce script doit être sourcé depuis un script principal (ex. build.sh).
# Ne pas l'exécuter directement en CLI.
################################################################################

# -----------------------------------------------------------------------------
# Vérification : ce module doit être sourcé, pas exécuté directement
# -----------------------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
  echo "Ce script doit être sourcé, pas exécuté directement." >&2
  return 1 2>/dev/null || exit 1
}

################################################################################
# install_core_packages : Installe les paquets listés dans le fichier de configuration
# Source de configuration : ${SCRIPT_DIR}/config/packages_to_install.list
################################################################################
install_core_packages() {
  local file="${SCRIPT_DIR}/config/packages_to_install.list"

  log_info "Installation des paquets de base nécessaires..."

  if [[ ! -f "${file}" ]]; then
    log_warning "Fichier introuvable : ${file}. Aucun paquet installé."
    return 0
  fi

  while read -r line; do
    # Supprime les commentaires inline
    pkg="${line%%#*}"
    pkg="$(echo "${pkg}" | xargs)"  # Supprime les espaces en début/fin

    # Ignorer les lignes vides
    [[ -z "${pkg}" ]] && continue

    if dpkg -s "${pkg}" &>/dev/null; then
      log_info "Paquet déjà installé : ${pkg}. Ignoré."
    else
      if apt-get install -y "${pkg}"; then
        log_info "Paquet installé avec succès : ${pkg}"
      else
        log_error "Échec de l'installation du paquet : ${pkg}"
      fi
    fi
  done < "${file}"

  log_info "Installation des paquets terminée."
  return 0
}
