#!/usr/bin/env bash
###############################################################################
# common.sh
#
# Description : Fonctions utilitaires pour scripts de post-installation
# Version     : 1.0.0
# Auteur      : Alan MARCHAND (keltalan@proton.me)
#
# Ce fichier contient les fonctions partagées par les autres scripts :
# - Fonctions de journalisation (log_debug, log_info, etc.)
# - handle_script_error (gestion des erreurs via trap)
# - check_caller_script (vérifie l'appelant autorisé)
# - check_root (vérifie les privilèges root)
# - lock_guard (empêche les exécutions simultanées)
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
# 🔧 Initialisation sécurisée de la variable DEBUG
#
# Cette ligne garantit que la variable DEBUG est toujours définie,
# même si elle n'existe pas dans l'environnement au moment du lancement
# du script. Cela évite les erreurs avec `set -u` (mode strict).
#
# La syntaxe `${DEBUG:-false}` signifie :
# - Si DEBUG est déjà définie, on garde sa valeur.
# - Sinon, on lui donne la valeur "false" par défaut.
#
# Ensuite, `export` rend la variable visible dans tout le script :
# - Les fonctions comme `log()` peuvent l'utiliser.
# - Les scripts sourcés ou les sous-shells peuvent y accéder.
#
# Cela permet d'activer le mode debug avec :
#   DEBUG=true ./mon_script.sh
#
# Et d'assurer un comportement cohérent même sans définition préalable.
# -----------------------------------------------------------------------------
export DEBUG="${DEBUG:-false}"


# -----------------------------------------------------------------------------
# Définition des couleurs ANSI (si NOCOLOR ≠ true)
# -----------------------------------------------------------------------------
if [[ "${NOCOLOR:-false}" == "true" ]]; then
  GREEN=''; YELLOW=''; RED=''; BLUE=''; LIGHT_BLUE=''; NC=''
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
      if [[ "${DEBUG}" == "true" ]]; then
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


################################################################################
# lock_guard : Empêche l'exécution simultanée du script
#
# Cette fonction vérifie si une autre instance du script est déjà en cours
# d'exécution en inspectant les fichiers de verrou (lock) dans un répertoire
# donné. Si un fichier lock est détecté et que le processus associé est actif,
# le script est interrompu pour éviter les conflits.
#
# Le nom du fichier de lock est fourni par l'appelant, et doit inclure le PID.
# La fonction ajoute l'extension ".lock" si elle est absente.
#
# 🔧 Usage :
#   lock_guard <chemin_complet_avec_pid> [force]
#
#   - <chemin_complet_avec_pid> : chemin complet incluant le PID.
#     Exemple : "/tmp/mon_script_pid1234" → /tmp/mon_script_pid1234.lock
#
#   - [force] : chaîne "true" pour ignorer les conflits et forcer l'exécution.
#
#   - Si aucun argument n'est fourni, le nom par défaut "/tmp/script_pid" est
#     utilisé, ce qui génère un fichier lock nommé "/tmp/script_pid.lock".
#
# ⚠️ Attention :
#   - Si le nom fourni se termine par ".lock", l'extension est retirée
#     automatiquement pour éviter des doublons du type
#     "mon_script_pid1234.lock.lock". Un message d'avertissement est affiché.
#
# 📌 Exemples :
#   lock_guard "/var/lock/backup1234"     → /var/lock/backup1234.lock
#   lock_guard "/tmp/mon_script_pid$$"    → /tmp/mon_script_pid12345.lock
#   lock_guard "/tmp/mon_script_12345"    → /tmp/mon_script_12345.lock
#   lock_guard                            → /tmp/script_pid.lock
#
# 🧹 À propos de `trap` :
#   Le trap 'rm -f ...' EXIT garantit la suppression du fichier lock à la fin
#   du script, même en cas d'erreur. Il ne s'exécute pas si le processus est
#   tué brutalement (ex. SIGKILL via kill -9).
################################################################################
lock_guard() {
  local lock_path="${1:-/tmp/script_pid}"   # Chemin de base du fichier de lock
  local force_mode="${2:-false}"            # Mode "force" pour ignorer conflit

  # 🔧 Nettoyage : retirer l'extension .lock si elle est déjà présente
  if [[ "${lock_path}" == *.lock ]]; then
    log_warning "🔧 Le nom fourni se termine par '.lock'."
    log_warning "L'extension a été retirée automatiquement."
    log_info "📍 Fichier lock corrigé : ${lock_path}.lock"
    lock_path="${lock_path%.lock}"
  fi

  # 📦 Construction du chemin complet du fichier de lock
  local lock_file="${lock_path}.lock"
  local lock_dir base_name
  lock_dir="$(dirname "${lock_path}")"
  base_name="$(basename "${lock_path}")"

  # 🔍 Recherche des fichiers de lock existants
  shopt -s nullglob
  local lock_files=(${lock_dir}/${base_name}*.lock)
  shopt -u nullglob
  local conflict=false

  if (( ${#lock_files[@]} > 0 )); then
    log_info "📋 Fichiers lock détectés :"

    for file in "${lock_files[@]}"; do
      local filename="${file##*/}"
      local pid="${filename#${base_name}}"
      pid="${pid%%.lock}"

      # 🚫 Ignorer le fichier de lock du processus courant
      if [[ "$pid" == "$$" ]]; then
        continue
      fi

      # ✅ Vérifier si le processus est encore actif
      if ps -p "$pid" > /dev/null 2>&1; then
        log_info "  - $file (✅ actif)"
        conflict=true
      else
        log_info "  - $file (❌ inactif)"
        rm -f "$file" && log_debug "🧹 Fichier lock supprimé : $file"
      fi
    done
  fi

  # 🛑 Si conflit détecté et mode force désactivé, arrêter le script
  if [[ "$conflict" == true && "$force_mode" != "true" ]]; then
    log_fatal "Arrêt du script pour éviter les conflits."
    log_fatal "Utilisez --force pour ignorer les verrous actifs."
  fi

  # 🔐 Création du fichier de lock pour le processus courant
  echo $$ > "${lock_file}"

  # 🧼 Nettoyage automatique du fichier de lock à la fin du script
  #
  # ⚠️ Problème rencontré :
  # La commande trap enregistrait : 'rm -f "${lock_file}"'
  # Or, cette syntaxe conserve la variable non résolue jusqu'à l'exécution.
  # À la fin du script, 'lock_file' n'existe plus (variable locale disparue),
  # ce qui provoque une erreur : "lock_file : variable sans liaison".
  #
  # 🧠 Explication technique :
  # Bash n'interpole pas les variables dans les chaînes simples du trap.
  # Il exécute le contenu du trap tel quel, sans substitution préalable.
  #
  # ✅ Solution :
  # Utiliser des guillemets doubles pour forcer l'interpolation immédiate.
  # Ainsi, la valeur de 'lock_file' est insérée au moment du trap.
  # Exemple corrigé : trap "rm -f ${lock_file}" EXIT
  #
  # 🧪 Résultat :
  # Le fichier de lock est supprimé proprement sans erreur en fin de script.
  trap "rm -f ${lock_file}" EXIT

  log_debug "🔓 Fichier lock créé : ${lock_file}"
}

