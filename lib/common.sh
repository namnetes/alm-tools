#!/usr/bin/env bash
###############################################################################
# common.sh
#
# Description : Fonctions utilitaires pour scripts de post-installation
# Version     : 1.0.0
# Auteur      : Alan MARCHAND (galan.marchand@outlook.fr)
#
# Ce fichier contient les fonctions partagées par les autres scripts :
# - Fonctions de journalisation (log_debug, log_info, etc.)
# - handle_script_error (gestion des erreurs via trap)
# - check_caller_script (vérifie l'appelant autorisé)
# - check_root (vérifie les privilèges root)
#
# Usage : Ce script doit être sourcé, pas exécuté directement.
###############################################################################

# -----------------------------------------------------------------------------
# Vérification : empêche l'exécution directe du fichier
# -----------------------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
  echo "Ce script doit être sourcé, pas exécuté directement." >&2
  exit 1
}

# -----------------------------------------------------------------------------
# Définition des couleurs ANSI (si NOCOLOR ≠ true)
# -----------------------------------------------------------------------------
if [[ "${NOCOLOR:-false}" == "true" ]]; then
  GREEN=''
  YELLOW=''
  RED=''
  BLUE=''
  LIGHT_BLUE=''
  NC=''
else
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  LIGHT_BLUE='\033[0;94m'
  NC='\033[0m'
fi

################################################################################
# log : Fonction générique de journalisation
# Usage : log <NIVEAU> <MESSAGE>
################################################################################
log() {
  local level=$1
  local message=$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  case "${level}" in
    DEBUG)
      if [[ "${DEBUG:-}" == "true" ]]; then
        echo -e "${LIGHT_BLUE}[${timestamp}] [DEBUG] ${message}${NC}" >&2
      fi
      ;;
    INFO)
      echo -e "${BLUE}[${timestamp}] [INFO] ${message}${NC}"
      ;;
    SUCCESS)
      echo -e "${GREEN}[${timestamp}] [SUCCESS] ${message}${NC}"
      ;;
    WARNING)
      echo -e "${YELLOW}[${timestamp}] [WARNING] ${message}${NC}" >&2
      ;;
    ERROR)
      echo -e "${RED}[${timestamp}] [ERROR] ${message}${NC}" >&2
      ;;
    FATAL)
      echo -e "${RED}[${timestamp}] [FATAL] ${message}${NC}" >&2
      exit 1
      ;;
    *)
      echo -e "${NC}[${timestamp}] [UNKNOWN] ${message}${NC}" >&2
      ;;
  esac
}

################################################################################
# Fonctions de journalisation spécifiques
################################################################################
log_debug()   { log DEBUG "$1"; }
log_info()    { log INFO "$1"; }
log_success() { log SUCCESS "$1"; }
log_warning() { log WARNING "$1"; }
log_error()   { log ERROR "$1"; }
log_fatal()   { log FATAL "$1"; }

################################################################################
# handle_script_error : Appelé via 'trap ERR' pour intercepter les erreurs
################################################################################
handle_script_error() {
  local last_command="${BASH_COMMAND}"
  local error_code="$?"

  log_error "Une erreur est survenue dans le script."
  log_error "Commande échouée : '${last_command}'"
  log_fatal "Code de sortie : ${error_code}. Arrêt du script."
}

################################################################################
# check_root : Arrête le script si l'utilisateur n'est pas root
################################################################################
check_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    log_fatal "Ce script doit être exécuté avec les privilèges root."
  fi
  log_debug "Exécution en tant que root détectée."
}

################################################################################
# check_caller_script : Vérifie que l'appelant est 'run_build.sh'
################################################################################
check_caller_script() {
  local -r script_autorise="run_build.sh"
  local ligne_appelante
  ligne_appelante=$(ps -o args= -p "${PPID}" 2>/dev/null)

  local nom_appelant
  if [[ -n "${ligne_appelante}" ]]; then
    nom_appelant=$(basename "${ligne_appelante%% *}")
  else
    nom_appelant="inconnu"
  fi

  if [[ "$nom_appelant" == "bash" || "$nom_appelant" == "sh" ||
        "$nom_appelant" == "sudo" ]]; then
    log_debug "Appelé via un shell ou sudo. Vérification non requise."
  elif [[ "$nom_appelant" != "$script_autorise" ]]; then
    log_error "Appel non autorisé : '${nom_appelant}' au lieu de" \
              "'${script_autorise}'."
  else
    log_info "Script appelant : ${nom_appelant}"
  fi
}
