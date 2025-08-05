#!/usr/bin/env bash
################################################################################
# update_snap.sh
#
# Description :
# Ce module gère la mise à jour et l’installation des paquets Snap :
# - Lit les snaps listés dans config/snap_packages.list
# - Tente de stopper les applications Snap actives correspondantes
# - Rafraîchit les snaps installés (snap refresh)
# - Installe les snaps manquants avec options éventuelles
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
# update_snap : Met à jour les snaps et installe ceux listés dans le fichier
# Source de configuration : ${SCRIPT_DIR}/config/snap_packages.list
################################################################################
update_snap() {
  local list_file="${SCRIPT_DIR}/config/snap_packages.list"

  log_info "Mise à jour des paquets Snap..."

  if [[ ! -f "${list_file}" ]]; then
    log_warning "Fichier introuvable : ${list_file}. Aucun snap traité."
    return 0
  fi

  # Étape 1 : Tentative d'arrêt des applications Snap listées
  log_debug "Tentative d'arrêt des applications Snap listées dans ${list_file}"

  while read -r line; do
    [[ -z "${line}" || "${line}" =~ ^# ]] && continue
    local snap_name=$(awk '{print $1}' <<< "${line}")

    pkill "${snap_name}" >/dev/null 2>&1 \
      && log_debug "Snap interactif stoppé : ${snap_name}" \
      || log_debug "Snap ${snap_name} non actif ou déjà fermé."
  done < "${list_file}"

  # 🔄 Étape 2 : Mise à jour globale des snaps
  if [[ "${DEBUG:-}" == "true" ]]; then
    log_debug "Commande exécutée : snap refresh"
  fi
  if ! snap refresh; then
    log_warning "Échec ou problème lors de snap refresh."
  fi

  # 📦 Étape 3 : Installation des snaps configurés
  while read -r line; do
    [[ -z "${line}" || "${line}" =~ ^# ]] && continue

    local snap_name option
    snap_name=$(awk '{print $1}' <<< "${line}")
    option=$(awk '{$1=""; print $0}' <<< "${line}" | xargs)

    if snap list | grep -q "^${snap_name}[[:space:]]"; then
      log_debug "Snap déjà installé : ${snap_name}. Ignoré."
      continue
    fi

    log_info "installation du package ${snap_name} ${option} en cours"

    if [[ "${DEBUG:-}" == "true" ]]; then
      log_debug "Commande exécutée : snap install ${snap_name} ${option}"
    fi

    if ! snap install "${snap_name}" ${option}; then
      log_warning "Échec de l'installation : ${snap_name} ${option}"
    else
      log_success "Snap installé : ${snap_name} ${option}"
    fi
  done < "${list_file}"

  log_info "Mise à jour des snaps terminée."
  return 0
}
