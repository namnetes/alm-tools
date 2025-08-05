#!/usr/bin/env bash
###############################################################################
# gdrivebak.sh
#
# Description : Sauvegarde incrémentale du remote Rclone 'googledrive'
#               avec versioning.
#
# Version     : 1.0.0
# Auteur      : Magali + Copilot
###############################################################################

# -----------------------------------------------------------------------------
# Chargement des fonctions utilitaires
# -----------------------------------------------------------------------------
COMMON_LIB="$HOME/alm-tools/lib/common.sh"
if [[ -f "${COMMON_LIB}" ]]; then
  source "${COMMON_LIB}"
else
  echo "Fichier common.sh introuvable à ${COMMON_LIB}" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Sécurité et gestion des erreurs
# -----------------------------------------------------------------------------
set -euo pipefail
trap handle_script_error ERR

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------

readonly REMOTE_NAME="googledrive"
readonly SOURCE_PATH="${REMOTE_NAME}:/"

readonly BACKUP_BASE="$HOME/backups/${REMOTE_NAME}"
readonly DEST_PATH="${BACKUP_BASE}/current"
readonly BACKUP_DIR_BASE="${BACKUP_BASE}/versions"
readonly TIMESTAMP=$(date +%F_%Hh%M)
readonly BACKUP_DIR="${BACKUP_DIR_BASE}/${TIMESTAMP}"

readonly LOCK_FILE="/tmp/rclone_backup_${REMOTE_NAME}.lock"
readonly MAX_VERSIONS=10

# -----------------------------------------------------------------------------
# Vérification des prérequis
# -----------------------------------------------------------------------------

log_info "🔍 Vérification des prérequis..."

if ! command -v rclone &> /dev/null; then
  log_fatal "❌ Rclone n’est pas installé ou introuvable dans \$PATH."
fi

if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
  log_fatal "❌ Le remote rclone '${REMOTE_NAME}' n’existe pas."
fi

mkdir -p "${DEST_PATH}" "${BACKUP_DIR_BASE}"

log_info "✅ Prérequis OK. Démarrage de la synchronisation..."

# -----------------------------------------------------------------------------
# DÉBUT DU SCRIPT
# -----------------------------------------------------------------------------

if [[ -e "${LOCK_FILE}" ]]; then
  log_warning "🔒 Une instance du script est déjà en cours. Abandon."
  exit 1
fi
touch "${LOCK_FILE}"

if [[ -d "${BACKUP_DIR}" ]]; then
  log_warning "🕒 Une sauvegarde existe déjà pour ${TIMESTAMP}. Abandon."
  rm -f "${LOCK_FILE}"
  exit 0
fi
mkdir -p "${BACKUP_DIR}"

log_info "🚀 Démarrage de la sauvegarde vers '${DEST_PATH}'..."
if rclone sync "${SOURCE_PATH}" "${DEST_PATH}" \
    --backup-dir="${BACKUP_DIR}" \
    --log-level=INFO \
    --progress; then
  log_success "✅ Sauvegarde terminée avec succès."
else
  log_error "❌ La commande Rclone a échoué."
  rm -f "${LOCK_FILE}"
  exit 1
fi

log_info "🧹 Nettoyage des anciennes versions (max ${MAX_VERSIONS})..."
cd "${BACKUP_DIR_BASE}" || {
  log_error "❌ Impossible d'accéder au dossier des versions."
  rm -f "${LOCK_FILE}"
  exit 1
}
ls -dt */ | tail -n +$((MAX_VERSIONS + 1)) | xargs -r rm -rf
log_success "🗂️ Rotation terminée. Versions conservées : ${MAX_VERSIONS}"

rm -f "${LOCK_FILE}"
log_info "🏁 Script terminé proprement."
