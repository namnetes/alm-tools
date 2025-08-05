#!/usr/bin/env bash
################################################################################
# check_caller_script.sh
#
# Description :
# Ce module vérifie que le script courant est lancé par le script principal
# autorisé, en utilisant la variable d’environnement CALLER_SCRIPT.
# Il bloque l’exécution si cette variable ne correspond pas à la valeur attendue.
#
# Auteur : Magali + Copilot ✨
#
# Usage :
# Le script principal doit exporter : export CALLER_SCRIPT="run_build.sh"
# Le module doit être sourcé ensuite : source check_caller_script.sh
################################################################################

# -----------------------------------------------------------------------------
# Fonction : check_caller_script
# -----------------------------------------------------------------------------
check_caller_script() {
  local expected_caller="run_build.sh"

  # Vérification de la variable CALLER_SCRIPT
  if [[ -z "${CALLER_SCRIPT}" ]]; then
    log_error "Variable d’environnement CALLER_SCRIPT absente."
    log_error "Ce module doit être appelé via le script principal : ${expected_caller}"
    return 1
  fi

  log_debug "Script appelant déclaré via CALLER_SCRIPT : ${CALLER_SCRIPT}"
  log_debug "Script autorisé attendu : ${expected_caller}"

  if [[ "${CALLER_SCRIPT}" != "${expected_caller}" ]]; then
    log_error "Appel non autorisé depuis ${CALLER_SCRIPT}."
    log_error "Ce module est conçu pour être lancé uniquement depuis ${expected_caller}."
    return 1
  fi

  log_info "Appelant vérifié : ${CALLER_SCRIPT} est autorisé."
  return 0
}
