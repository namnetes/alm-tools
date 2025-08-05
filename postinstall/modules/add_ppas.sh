#!/usr/bin/env bash
################################################################################
# add_ppas.sh
#
# Description :
# Ce module gère l’ajout des dépôts PPAs :
# - Lit les PPAs depuis config/ppas.list
# - Vérifie leur présence dans les sources apt
# - Ajoute les PPAs manquants via add-apt-repository
# - Met à jour les listes APT si au moins un PPA a été ajouté
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
# add_ppas : Ajoute les PPAs listés dans le fichier de configuration
# Source de configuration : ${SCRIPT_DIR}/config/ppas.list
################################################################################
add_ppas() {
  local list_file="${SCRIPT_DIR}/config/ppas.list"

  log_info "Début de la gestion des dépôts PPA..."

  if [[ ! -f "${list_file}" ]]; then
    log_warning "Fichier introuvable : ${list_file}. Aucun PPA traité."
    return 0
  fi

  # Installation de l’utilitaire nécessaire à add-apt-repository
  if ! dpkg -s software-properties-common &>/dev/null; then
    log_info "Installation de 'software-properties-common' requise..."
    if ! apt-get update || ! apt-get install -y software-properties-common; then
      log_error "Impossible d’installer 'software-properties-common'."
      return 1
    fi
    log_success "'software-properties-common' installé avec succès."
  else
    log_debug "'software-properties-common' déjà installé."
  fi

  local ppa_added=false

  # Lecture de la configuration
  while read -r line; do
    [[ -z "${line}" || "${line}" =~ ^# ]] && continue

    local ppa="${line}"
    local user=$(echo "${ppa}" | cut -d':' -f2 | cut -d'/' -f1)
    local repo=$(echo "${ppa}" | cut -d':' -f2 | cut -d'/' -f2)
    local search="${user}/${repo}/ubuntu"

    if grep -qE "(^(deb|deb-src) .*${search}|URIs: .*${search})" \
      /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
      log_info "PPA déjà présent : ${ppa}"
    else
      log_info "Ajout du PPA : ${ppa}"
      if add-apt-repository --yes "${ppa}"; then
        log_success "PPA ajouté : ${ppa}"
        ppa_added=true
      else
        log_warning "Échec de l'ajout du PPA : ${ppa}"
      fi
    fi
  done < "${list_file}"

  # Mise à jour APT si nécessaire
  if ${ppa_added}; then
    log_info "Mise à jour des listes APT suite à l’ajout des PPAs..."
    if ! apt-get update; then
      log_error "Échec de mise à jour des listes APT."
      return 1
    fi
    log_success "Listes APT mises à jour."
  else
    log_info "Aucun nouveau PPA ajouté. Mise à jour APT non nécessaire."
  fi

  log_info "Gestion des PPAs terminée."
  return 0
}
