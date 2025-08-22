#!/usr/bin/env bash
################################################################################
# update_plocate_database.sh
#
# Description :
# Ce module met à jour la base de données utilisée par plocate :
# - Vérifie que plocate est installé sur le système
# - Exécute 'updatedb' pour rafraîchir l’index de recherche
#
# Si plocate est absent, la mise à jour est ignorée avec une notification.
# Le comportement est idempotent.
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
# update_plocate_database : Met à jour l’index utilisé par plocate
################################################################################
update_plocate_db() {
  log_info "Mise à jour de la base de données plocate..."

  if ! command -v plocate &>/dev/null; then
    log_warn "  [STATUT] plocate n’est pas installé. Mise à jour ignorée."
    log_warn "  [CONSEIL] Assurez-vous que 'plocate' est inclus dans CORE_PACKAGES."
    return 0
  fi

  log_info "  [ACTION] Exécution de 'updatedb'..."
  if ! updatedb; then
    log_error "  [ÉCHEC] Impossible de mettre à jour la base plocate. Vérifiez les permissions ou l’espace disque."
    return 1
  fi

  log_info "  [SUCCÈS] Base de données plocate mise à jour."
  return 0
}
