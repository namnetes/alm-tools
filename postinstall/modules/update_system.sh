#!/usr/bin/env bash
################################################################################
# update_system.sh
#
# Description :
# Ce module effectue la mise à jour du système via APT :
# - Récupère les listes de paquets avec apt-get update
# - Applique les mises à niveau disponibles avec apt-get dist-upgrade
# Le comportement est idempotent : aucune action inutile si le système est à jour.
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
# update_system : Met à jour les paquets via APT
################################################################################
update_system() {
  log_info "Mise à jour des paquets système..."

  if [[ "${DEBUG:-}" == "true" ]]; then
    log_debug "Commande exécutée : apt-get update"
  fi
  if ! apt-get update; then
    log_error "Échec de la mise à jour des listes APT."
    return 1
  fi

  if [[ "${DEBUG:-}" == "true" ]]; then
    log_debug "Commande exécutée : apt-get dist-upgrade -y"
  fi
  if ! apt-get dist-upgrade -y; then
    log_error "Échec de la mise à niveau des paquets système."
    return 1
  fi

  log_info "Mise à jour système terminée."
  return 0
}
