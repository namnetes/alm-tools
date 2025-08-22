#!/usr/bin/env bash
################################################################################
# cleanup_packages.sh
#
# Description :
# Ce module supprime les paquets système indésirables via APT :
# - Lit les paquets à supprimer listés dans config/packages_to_remove.list
# - Ignore les lignes vides ou commentées
# - Vérifie si le paquet est installé avant tentative de suppression
# - Supprime le paquet via apt-get purge s’il est présent
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
# cleanup_packages : Supprime les paquets listés dans le fichier de configuration
# Source de configuration : ${SCRIPT_DIR}/config/packages_to_remove.list
################################################################################
cleanup_packages() {
  local file="${SCRIPT_DIR}/config/packages_to_remove.list"

  log_info "Nettoyage des paquets obsolètes..."

  if [[ ! -f "${file}" ]]; then
    log_warning "Fichier introuvable : ${file}. Aucun paquet supprimé."
    return 0
  fi

  while read -r pkg; do
    # Ignorer les commentaires et les lignes vides
    [[ -z "${pkg}" || "${pkg}" =~ ^# ]] && continue

    if dpkg -s "${pkg}" >/dev/null 2>&1; then
      if apt-get purge -y "${pkg}"; then
        log_info "Paquet supprimé avec succès : ${pkg}"
      else
        log_error "Échec de suppression du paquet : ${pkg}"
      fi
    else
      log_info "Paquet non installé : ${pkg}. Aucune suppression effectuée."
    fi
  done < "${file}"

  log_info "Nettoyage des paquets terminé."
  return 0
}
