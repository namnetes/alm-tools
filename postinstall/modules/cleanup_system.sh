#!/usr/bin/env bash
################################################################################
# cleanup.sh
#
# Description :
# Ce module effectue le nettoyage du système :
# - Supprime les paquets obsolètes avec APT
# - Nettoie les caches Snap (réduction de l’historique de mises à jour)
# - Purge les fichiers temporaires dans /tmp et /var/tmp
# - Réduit la taille des journaux système avec journalctl
#
# Le nettoyage ignore les erreurs bénignes liées à Snap et conserve l'idempotence.
#
# Auteur : Alan MARCHAND
#
# Usage :
# Ce script doit être sourcé depuis un script principal (ex. build.sh).
# Ne pas l'exécuter directement depuis la ligne de commande.
################################################################################

# -----------------------------------------------------------------------------
# Vérification : ce module doit être sourcé, pas exécuté directement
# -----------------------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
  echo "Ce script doit être sourcé, pas exécuté directement." >&2
  return 1 2>/dev/null || exit 1
}

################################################################################
# cleanup : Nettoie les fichiers temporaires, les caches et les journaux
################################################################################
cleanup() {
  log_info "Nettoyage complet du système..."

  # --- Étape 1 : Nettoyage APT ---
  log_info "  [APT] Suppression des paquets inutiles (autoremove, clean, autoclean)..."
  apt-get -y autoremove --purge || log_warn "  [WARN] Échec autoremove (peut être sans incidence)."
  apt-get -y clean || log_warn "  [WARN] Échec clean."
  apt-get -y autoclean || log_warn "  [WARN] Échec autoclean."
  log_info "  [APT] Nettoyage APT terminé."

  # --- Étape 2 : Réduction des snapshots Snap ---
  log_info "  [Snap] Réduction de l’historique de rétention des paquets Snap..."
  set +e
  for snap_name in $(snap list | awk 'NR > 1 {print $1}'); do
    snap set "${snap_name}" refresh.retain=2 2>&1 | grep -vE "cannot configure|has no \"configure\" hook" > /dev/null
  done
  set -e
  log_info "  [Snap] Nettoyage Snap terminé."

  # --- Étape 3 : Suppression des fichiers temporaires ---
  log_info "  [Temp] Suppression des fichiers et dossiers temporaires..."
  find /tmp -type f -mtime +7 -delete || log_warn "  [WARN] Échec suppression fichiers /tmp."
  find /tmp -type d -empty -delete || log_warn "  [WARN] Échec suppression dossiers /tmp."
  find /var/tmp -type f -mtime +7 -delete || log_warn "  [WARN] Échec suppression fichiers /var/tmp."
  find /var/tmp -type d -empty -delete || log_warn "  [WARN] Échec suppression dossiers /var/tmp."
  log_info "  [Temp] Nettoyage des fichiers temporaires terminé."

  # --- Étape 4 : Purge des journaux système ---
  log_info "  [Journaux] Nettoyage des journaux avec journalctl..."
  journalctl --vacuum-time=7d || log_warn "  [WARN] Échec vacuum par date."
  journalctl --vacuum-size=100M || log_warn "  [WARN] Échec vacuum par taille."
  log_info "  [Journaux] Nettoyage des journaux terminé."

  log_info "[SUCCÈS] Nettoyage complet du système terminé."
  return 0
}
