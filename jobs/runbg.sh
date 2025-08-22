#!/usr/bin/env bash

################################################################################
# Nom du script : runbg.sh
#
# Objectif :
# Ce script lance un autre script en arrière-plan en utilisant la commande nohup.
# Il gère la journalisation, l'utilisation de fichiers d'environnement et les
# notifications locales, tout en assurant une gestion robuste des erreurs.
#
# 👤 Auteur :
# Alan MARCHAND (keltalan@proton.me)
#
# Compatibilité :
# Conçu pour fonctionner avec Bash. Testé sur les systèmes Ubuntu et Debian.
#
# tilisation :
# - Lancer un script en arrière-plan avec une journalisation persistante.
# - Exemple : ./runbg.sh --name "mon_job" --notify /chemin/vers/mon_script.sh
#
# Fonctionnement général :
# 1. Définit les options de sécurité pour une exécution fiable.
# 2. Charge des fonctions utilitaires communes.
# 3. Gère les arguments de ligne de commande.
# 4. Effectue des validations sur le script à lancer.
# 5. Crée le répertoire de logs si nécessaire.
# 6. Lance le script en arrière-plan et capture la sortie dans un fichier de log.
# 7. Affiche des informations sur le processus et le fichier de log généré.
################################################################################


# -----------------------------------------------------------------------------
# Sécurité et gestion des erreurs
# -----------------------------------------------------------------------------
# Active trois options de sécurité pour un script plus fiable.
# -e : arrête le script si une commande échoue
# -u : arrête si une variable non définie est utilisée
# -o pipefail : détecte les erreurs dans les pipelines
set -euo pipefail

# La commande trap intercepte le signal d'erreur et appelle la fonction
# 'handle_script_error' qui est définie dans le fichier 'common.sh'
trap handle_script_error ERR


# -----------------------------------------------------------------------------
# Chargement des fonctions utilitaires
# -----------------------------------------------------------------------------
COMMON_LIB="$HOME/alm-tools/lib/common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
  source "${COMMON_LIB}"
else
  log_fatal "Fichier common.sh introuvable à ${COMMON_LIB}"
fi


# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
# Déclaration des variables de configuration avec le mot-clé 'readonly'
# pour éviter toute modification accidentelle.
readonly LOG_DIR="$HOME/.nohups"

# Variables par défaut, modifiables par les options de ligne de commande.
SCRIPT_PATH=""
CUSTOM_NAME=""
ENV_FILE=""
NOTIFY=false


# -----------------------------------------------------------------------------
# Fonctions principales
# -----------------------------------------------------------------------------

# Affiche le mode d'emploi du script.
usage() {
  echo "Usage: $0 [options] <script.sh>"
  echo ""
  echo "Options :"
  echo "  --name <nom>        Nom personnalisé pour le log (par défaut : nom du script)"
  echo "  --env <fichier>     Fichier d'environnement à sourcer avant l'exécution"
  echo "  --notify            Envoie une notification locale (si notify-send dispo)"
  echo "  --help              Affiche cette aide"
  exit 1
}

# Crée le dossier de logs si il n'existe pas.
prepare_log_dir() {
  if [[ ! -d "$LOG_DIR" ]]; then
    log_info "Création du dossier de logs : $LOG_DIR"
    mkdir -p "$LOG_DIR"
  fi
}

# Génère un nom de fichier de log unique basé sur le nom personnalisé et
# un horodatage.
generate_logfile() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  echo "$LOG_DIR/${CUSTOM_NAME}_$timestamp.out"
}

# Lance le script en arrière-plan avec les options configurées.
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

  if "$NOTIFY" && command -v notify-send &>/dev/null; then
    notify-send "Script lancé" "$SCRIPT_PATH (PID $pid)"
  fi
}


# -----------------------------------------------------------------------------
# Parsing des options
# -----------------------------------------------------------------------------
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
    --) # Fin des options
      shift
      break
      ;;
    -*)
      log_error "Option inconnue : $1"
      usage
      ;;
    *) # Capture le chemin du script
      SCRIPT_PATH="$1"
      shift
      ;;
  esac
done


# -----------------------------------------------------------------------------
# Validtion du nom de script à lancer.
# -----------------------------------------------------------------------------
if [[ -z "$SCRIPT_PATH" ]]; then
  log_fatal "Aucun script fourni."
  usage
fi


# -----------------------------------------------------------------------------
# Validations et exécution
# -----------------------------------------------------------------------------

# Vérifie qu'un script a été fourni en argument.
if [[ -z "$SCRIPT_PATH" ]]; then
  log_fatal "Aucun script fourni."
  usage
fi

# Vérifie que le script fourni existe et est un fichier régulier.
if [[ ! -f "$SCRIPT_PATH" ]]; then
  log_fatal "Le fichier '$SCRIPT_PATH' n'existe pas."
fi

# Vérifie si le script est exécutable. Si non, tente d'ajouter les permissions.
if [[ ! -x "$SCRIPT_PATH" ]]; then
  log_warning "Le script n'est pas exécutable. Ajout des droits."
  chmod +x "$SCRIPT_PATH" || log_fatal "Échec de l'ajout des droits d'exécution."
fi

# Définit le nom de log par défaut si aucun nom personnalisé n'a été fourni.
if [[ -z "$CUSTOM_NAME" ]]; then
  CUSTOM_NAME="$(basename "$SCRIPT_PATH")"
  CUSTOM_NAME="${CUSTOM_NAME%.*}"
  log_info "Nom de log par défaut : $CUSTOM_NAME"
fi

# Exécution des fonctions principales.
prepare_log_dir
launch_script

exit 0
