#!/usr/bin/env bash
###############################################################################
# runbg.sh
#
# Description : Lance un script en arrière-plan avec nohup, journalisation,
#               et options avancées.
# Version     : 1.1.0
# Auteur      : Alan MARCHAND (modifié par Magali & Copilot)
###############################################################################

set -euo pipefail
trap handle_script_error ERR

# === SOURCING DES FONCTIONS COMMUNES ===
source ~/alm-tools/lib/common.sh

# === CONFIGURATION PAR DÉFAUT ===
LOG_DIR="$HOME/.nohups"
SCRIPT_PATH=""
CUSTOM_NAME=""
ENV_FILE=""
NOTIFY=false

# === FONCTIONS ===

usage() {
  echo "Usage: $0 [options] <script.sh>"
  echo ""
  echo "Options :"
  echo "  --name <nom>       Nom personnalisé pour le log (par défaut : nom du script)"
  echo "  --env <fichier>    Fichier d'environnement à sourcer"
  echo "  --notify           Envoie une notification locale (si notify-send dispo)"
  echo "  --help             Affiche cette aide"
  exit 1
}

prepare_log_dir() {
  if [[ ! -d "$LOG_DIR" ]]; then
    log_info "Création du dossier de logs : $LOG_DIR"
    mkdir -p "$LOG_DIR"
  fi
}

generate_logfile() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  echo "$LOG_DIR/${CUSTOM_NAME}_$timestamp.out"
}

launch_script() {
  local logfile
  logfile=$(generate_logfile)

  if [[ -n "$ENV_FILE" ]]; then
    log_info "Chargement des variables d'environnement depuis : $ENV_FILE"
    source "$ENV_FILE"
  fi

  log_info "Lancement du script en arrière-plan : $SCRIPT_PATH"
  nohup bash "$SCRIPT_PATH" > "$logfile" 2>&1 &
  local pid=$!

  log_success "Script lancé avec succès (PID : $pid)"
  log_info "Log disponible ici : $logfile"

  if $NOTIFY && command -v notify-send >/dev/null 2>&1; then
    notify-send "Script lancé" "$SCRIPT_PATH (PID $pid)"
  fi
}

# === PARSING DES OPTIONS ===

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --name)
      CUSTOM_NAME="$2"
      shift 2
      ;;
    --env)
      ENV_FILE="$2"
      shift 2
      ;;
    --notify)
      NOTIFY=true
      shift
      ;;
    --help)
      usage
      ;;
    --*)
      log_error "Option inconnue : $1"
      usage
      ;;
    *)
      SCRIPT_PATH="$1"
      shift
      ;;
  esac
done

# === VALIDATIONS ===

if [[ -z "$SCRIPT_PATH" ]]; then
  log_fatal "Aucun script fourni."
fi

if [[ ! -f "$SCRIPT_PATH" ]]; then
  log_fatal "Le fichier '$SCRIPT_PATH' n'existe pas."
fi

if [[ ! -x "$SCRIPT_PATH" ]]; then
  log_warning "Le script n'est pas exécutable. Ajout des droits."
  chmod +x "$SCRIPT_PATH"
fi

# === NOM PAR DÉFAUT SI NON FOURNI ===
if [[ -z "$CUSTOM_NAME" ]]; then
  CUSTOM_NAME="$(basename "$SCRIPT_PATH")"
  CUSTOM_NAME="${CUSTOM_NAME%.*}"
  log_debug "Nom personnalisé par défaut : $CUSTOM_NAME"
fi

prepare_log_dir
launch_script
