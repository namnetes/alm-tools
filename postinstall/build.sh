#!/usr/bin/env bash
################################################################################
# Nom du script : build.sh
#
# Description :
# Script de post-installation pour Ubuntu 24.04.
# Il installe les outils, configure les dépôts et effectue un nettoyage système.
#
# Idempotence :
# Ce script peut être exécuté plusieurs fois sans générer d'effets secondaires.
# Chaque opération vérifie l'état du système avant d'agir.
#
# Auteur : Alan MARCHAND (galan.marchand@outlook.fr)
# Compatibilité : Bash uniquement (Ubuntu/Debian)
#
# Utilisation :
# Ce script doit être lancé via 'run_build.sh' avec les privilèges root.
################################################################################

# -----------------------------------------------------------------------------
# Aide : affichage des options disponibles
# -----------------------------------------------------------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Script de post-installation pour Ubuntu 24.04."
  echo
  echo "Options disponibles :"
  echo "  -h, --help     Affiche cette aide."
  echo
  echo "DEBUG : pour activer le mode débogage, définir DEBUG=true."
  echo "Attention : avec sudo, la variable DEBUG doit être transmise ainsi :"
  echo "  sudo DEBUG=true ./build.sh"
  echo "ou, avec préservation d'environnement :"
  echo "  DEBUG=true sudo -E ./build.sh"
  exit 0
fi

# -----------------------------------------------------------------------------
# Initialisation et chargement
# -----------------------------------------------------------------------------
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/common.sh"
log_debug "Répertoire principal : ${SCRIPT_DIR}"

# -----------------------------------------------------------------------------
# Paramètres généraux
# -----------------------------------------------------------------------------
# set -eo pipefail  # Décommentez pour activer l'arrêt à la première erreur

# Mode débogage
if [[ "${DEBUG:-}" == "true" ]]; then
  set -x
  log_debug "Mode débogage activé."
fi

# Gestion des erreurs
trap 'handle_script_error' ERR

# -----------------------------------------------------------------------------
# Chargement des modules
# -----------------------------------------------------------------------------
source "${SCRIPT_DIR}/modules/check_caller_script.sh"
source "${SCRIPT_DIR}/modules/update_system.sh"
source "${SCRIPT_DIR}/modules/update_snap.sh"
source "${SCRIPT_DIR}/modules/cleanup_packages.sh"
source "${SCRIPT_DIR}/modules/add_ppas.sh"
source "${SCRIPT_DIR}/modules/install_core_packages.sh"
source "${SCRIPT_DIR}/modules/install_uv.sh"
source "${SCRIPT_DIR}/modules/install_xan.sh"
source "${SCRIPT_DIR}/modules/install_starship.sh"
source "${SCRIPT_DIR}/modules/install_githubcli.sh"
source "${SCRIPT_DIR}/modules/install_fzf.sh"
source "${SCRIPT_DIR}/modules/install_firacode.sh"
source "${SCRIPT_DIR}/modules/cleanup_system.sh"
source "${SCRIPT_DIR}/modules/update_plocate_db.sh"

# -----------------------------------------------------------------------------
# Vérifications initiales
# -----------------------------------------------------------------------------
log_info "Vérification de l'appelant : seul 'run_build.sh' est autorisé."
check_caller_script

log_info "Vérification des privilèges : ce script nécessite les droits root."
check_root

# -----------------------------------------------------------------------------
# Suite des installations
# -----------------------------------------------------------------------------

# Étape 1 : Mise à jour APT
log_info "Étape 1/12 : Mise à jour du système (APT)."
if update_system; then
  log_success "Mise à jour APT terminée."
else
  log_warning "Échec lors de la mise à jour APT."
fi

# Étape 2 : Mise à jour Snap
log_info "Étape 2/12 : Mise à jour des paquets Snap."
if update_snap; then
  log_success "Mise à jour Snap terminée."
else
  log_warning "Échec lors de la mise à jour Snap."
fi

# Étape 3 : Nettoyage des paquets inutiles
log_info "Étape 3/12 : Nettoyage des paquets inutiles."
if cleanup_packages; then
  log_success "Nettoyage terminé."
else
  log_warning "Échec lors du nettoyage des paquets."
fi

# Étape 4 : Ajout des dépôts PPA
log_info "Étape 4/12 : Ajout des dépôts PPA."
if add_ppas; then
  log_success "Ajout des PPAs terminé."
else
  log_warning "Échec lors de l'ajout des PPAs."
fi

# Étape 5 : Installation des paquets essentiels
log_info "Étape 5/12 : Installation des paquets de base."
if install_core_packages; then
  log_success "Installation des paquets essentiels terminée."
else
  log_warning "Échec lors de l'installation des paquets de base."
fi

# Étape 6 : Installation du gestionnaire UV
log_info "Étape 6/12 : Installation du gestionnaire Python UV."
if install_uv; then
  log_success "UV installé avec succès."
else
  log_warning "Échec lors de l'installation de UV."
fi

# Étape 7 : Installation de Xan (CSV Magician)
log_info "Étape 7/12 : Installation de Xan, outil magique pour les CSV."
if install_xan; then
  log_success "Xan installé avec succès."
else
  log_warning "Échec lors de l'installation de Xan."
fi

# Étape 8 : Installation de Starship (prompt universel)
log_info "Étape 8/12 : Installation de Starship, l’invite multiplateforme."
if install_starship; then
  log_success "Starship installé avec succès."
else
  log_warning "Échec lors de l'installation de Starship."
fi

# Étape 9 : Installation de GitHub CLI
log_info "Étape 9/12 : Installation de GitHub CLI (gh)."
if install_githubcli; then
  log_success "GitHub CLI installé avec succès."
else
  log_warning "Échec lors de l'installation de GitHub CLI."
fi

# Étape 10 : Installation de fzf
log_info "Étape 10/12 : Installation de fzf."
if install_fzfe; then
  log_success "fzf installée avec succès."
else
  log_warning "Échec lors de l'installation de fzf."
fi

# Étape 11 : Installation de la police FiraCode Nerd Font
log_info "Étape 11/12 : Installation de la police FiraCode Nerd Font."
if install_firacode; then
  log_success "FiraCode Nerd Font installée avec succès."
else
  log_warning "Échec lors de l'installation de la police."
fi

# Étape 12 : Mise à jour de la base de données plocate
log_info "Étape 12/12 : Mise à jour de la base plocate."
log_debug "Appel de update_plocate_database..."
if update_plocate_db; then
  log_success "Mise à jour de la base plocate terminée."
else
  log_warning "La mise à jour plocate a échoué."
fi
log_debug "update_plocate_db terminé."

# -----------------------------------------------------------------------------
# Fin du script
# -----------------------------------------------------------------------------
log_info "Toutes les étapes du post-installation ont été exécutées."
log_success "Script terminé."
exit 0
