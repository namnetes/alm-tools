#!/usr/bin/env bash

################################################################################
# Nom du script : backup_googledrive.sh
#
# Objectif :
# Ce script automatise la sauvegarde de fichiers depuis Google Drive.
# Il utilise l'outil rclone pour synchroniser les données.
# Il historise dans une archive tar.gz les versions.
#
# Auteur :
# Alan MARCHAND (keltalan@proton.me)
#
# Compatibilité :
# Ce script est conçu pour fonctionner uniquement avec Bash.
# Testé sur les systèmes Ubuntu et Debian.
#
# tilisation :
# - Peut être lancé manuellement depuis un terminal.
# - Peut être intégré dans une tâche planifiée (cron).
#
# Fonctionnement général :
# 1. Vérifie que les outils nécessaires sont installés.
# 2. Crée les répertoires de sauvegarde et d'archive si besoin.
# 3. Empêche l'exécution simultanée de plusieurs instances du script.
# 4. Crée une archive compressée des fichiers synchronisés.
# 5. Synchronise les fichiers depuis Google Drive vers un dossier local.
# 7. Enregistre les logs et affiche les messages d'état.
#
# Pour les débutants :
# - Chaque commande est commentée dans le script pour faciliter la lecture.
# - Les erreurs sont gérées automatiquement pour éviter les plantages.
# - Le script est structuré en sections claires pour une meilleure compréhension.
#
# Exemple de structure de répertoires :
# $HOME/backups/googledrive     → Dossier de sauvegarde local
# $HOME/backups/archives        → Dossier contenant les archives compressées
################################################################################


# -----------------------------------------------------------------------------
# Sécurité et gestion des erreurs
# -----------------------------------------------------------------------------
# Active trois options de sécurité pour rendre le script plus fiable.
# -e : arrête le script si une commande échoue
# -u : arrête si une variable non définie est utilisée
# -o pipefail : détecte les erreurs dans les pipelines
set -euo pipefail


# -----------------------------------------------------------------------------
# Gestion des erreurs avec trap
# -----------------------------------------------------------------------------
# La commande trap permet d'intercepter certains événements pendant l'exécution.
# Elle est souvent utilisée pour réagir à des erreurs ou nettoyer avant de sortir.
#
# Syntaxe : trap <action> <signal>
# Ici, l'action est d'appeler la fonction handle_script_error.
# Le signal ERR est déclenché dès qu'une commande échoue (exit code ≠ 0).
#
# Cela signifie que si une commande échoue dans le script,
# la fonction handle_script_error sera automatiquement exécutée.
# Cette fonction peut afficher un message, enregistrer une erreur,
# ou effectuer un nettoyage avant de quitter le script.
#
# Ce mécanisme rend le script plus robuste et plus facile à déboguer.
trap handle_script_error ERR


# -----------------------------------------------------------------------------
# Fonction de gestion des erreurs
# -----------------------------------------------------------------------------
# Cette fonction affiche un message d'erreur et supprime le fichier de verrou.
# Elle est appelée automatiquement si une erreur survient dans le script.
handle_script_error() {
  echo "❌ Une erreur est survenue. Arrêt du script." >&2
  rm -f "${LOCK_FILE:-/tmp/gdrivebak_lock}"
  exit 1
}


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
# Configuration
# -----------------------------------------------------------------------------
readonly RCLONE_REMOTE="googledrive"
readonly SOURCE_DIR=""
readonly BACKUP_DIR="$HOME/backups/googledrive"
readonly ARCHIVE_DIR="$HOME/backups/archives"
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_BASENAME="${SCRIPT_NAME%.*}"
readonly LOCK_FILE="/tmp/${SCRIPT_BASENAME}_pid$$"


# -----------------------------------------------------------------------------
# Vérifications des prérequis
# -----------------------------------------------------------------------------

log_info "Vérification des outils nécessaires : rclone, pv & hashdeep."
command -v rclone &> /dev/null || { log_error "rclone n'est pas installé."; exit 1; }
command -v pv &> /dev/null || { log_error "pv n'est pas installé."; exit 1; }
command -v hashdeep &> /dev/null || { log_error "hasdeep n'est pas installé."; exit 1; }

log_info "Création des répertoires de sauvegarde et d'archive si nécessaires."
mkdir -p "$BACKUP_DIR"
mkdir -p "$ARCHIVE_DIR"


# -----------------------------------------------------------------------------
# Affichage de la configuration
# -----------------------------------------------------------------------------
log_info "📁 Configuration des répertoires et paramètres :"
log_info "-> Vérification des privilèges : pas besoin de root ici."
log_info "-> Remote Rclone utilisé       : $RCLONE_REMOTE"
log_info "-> Répertoire source           : $SOURCE_DIR"
log_info "-> Répertoire de backup local  : $BACKUP_DIR"
log_info "-> Répertoire d'archives       : $ARCHIVE_DIR"
log_info "-> Nom du script               : $SCRIPT_NAME"
log_info "-> Nom de base du script       : $SCRIPT_BASENAME"
log_info "-> Fichier de verrouillage     : $LOCK_FILE"


# -----------------------------------------------------------------------------
# Vérifie si une instance du script est déjà en cours
# -----------------------------------------------------------------------------
lock_guard "$LOCK_FILE"


# -----------------------------------------------------------------------------
# Synchronisation avec Google Drive
# -----------------------------------------------------------------------------
log_info "Début de la synchronisation avec Google Drive."

rclone sync "$RCLONE_REMOTE:$SOURCE_DIR" "$BACKUP_DIR" \
  --progress \
  --stats 1m \
  --log-file "$BACKUP_DIR/rclone_sync.log"

if [[ $? -eq 0 ]]; then
  log_success "Synchronisation terminée avec succès."
else
  log_warning "Erreur lors de la synchronisation. Voir le fichier de log."
fi


# -----------------------------------------------------------------------------
# Création d'une archive gzip de sauvegarde
# -----------------------------------------------------------------------------
log_info "Début de la création d'une nouvelle archive de sauvegarde."

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_FILE="$ARCHIVE_DIR/${RCLONE_REMOTE}_$TIMESTAMP.tar.gz"
ARCHIVE_FILE_SHA256="${ARCHIVE_FILE}.sha256.txt"
TOTAL_SIZE=$(du -bs "$BACKUP_DIR" | awk '{print $1}')

# ❌ Cette commande est abandonnée car elle ne produit pas une archive
# identique si le contenu source n'a pas changé. Elle est sensible aux
# métadonnées et à l'ordre des fichiers, ce qui modifie le hash final.
#
# tar -c -C "$BACKUP_DIR" . : crée une archive à partir du répertoire
# de sauvegarde, mais sans contrôle sur l'ordre des fichiers ni sur les
# métadonnées comme les dates ou les propriétaires.
#
# pv -s "$TOTAL_SIZE" : affiche une barre de progression pendant la
# compression, ce qui est utile mais n'influence pas le contenu.
#
# gzip -9 : compresse l'archive avec le niveau maximal, mais sans
# empêcher l'ajout de métadonnées comme le nom du fichier ou un
# timestamp dans l'en-tête gzip.
#
# > "$ARCHIVE_FILE" : enregistre le fichier final, mais son contenu
# varie à chaque exécution même si les fichiers source sont identiques.
#
# 👉 Pour garantir des sauvegardes fiables et comparables, une version
# déterministe est utilisée à la place, avec des options qui neutralisent
# les variations liées aux métadonnées et à la compression.
####
# tar -c -C "$BACKUP_DIR" . | pv -s "$TOTAL_SIZE" | gzip -9 > "$ARCHIVE_FILE"

# Cette commande crée une archive compressée de manière déterministe.
# Elle est utilisée pour sauvegarder un répertoire sans que le hash change
# si le contenu reste identique. Cela permet de détecter les vraies
# modifications entre deux sauvegardes.
#
# tar --sort=name : trie les fichiers par nom pour garantir un ordre stable.
# --mtime='UTC 2020-01-01' : fixe une date de modification neutre.
# --owner=0 --group=0 --numeric-owner : supprime les infos utilisateur/groupe.
# -c -C "$BACKUP_DIR" . : crée une archive à partir du répertoire de backup.
#
# pv -s "$TOTAL_SIZE" : affiche une barre de progression pendant le traitement.
#
# gzip -9 -n : compresse l’archive avec le niveau maximal (-9) et sans ajouter
# de métadonnées comme le nom du fichier ou un timestamp (-n).
#
# > "$ARCHIVE_FILE" : enregistre le résultat dans le fichier final .tar.gz.
#
# Grâce à cette méthode, deux archives identiques auront le même hash SHA256.
# Cela rend les sauvegardes comparables et fiables dans le temps.

tar --sort=name \
    --mtime='UTC 2020-01-01' \
    --owner=0 --group=0 --numeric-owner \
    -c -C "$BACKUP_DIR" . \
| pv -s "$TOTAL_SIZE" \
| gzip -9 -n \
> "$ARCHIVE_FILE"

if [ $? -eq 0 ]; then
  log_success "✅ Nouvelle archive créée : $ARCHIVE_FILE"
else
  log_error "❌ Erreur lors de la création de l'archive."
  exit 1
fi

hashdeep -c sha256 -l "$ARCHIVE_FILE" > "$ARCHIVE_FILE_SHA256"
if [ $? -eq 0 ]; then
  log_success "✅ Création du SHA256 de l'archive : $ARCHIVE_FILE_SHA256"

  # grep -v '^#' : ignore les lignes de commentaire
  # grep -v '^%%%%' : ignore les lignes de métadonnées
  # awk -F',' '{print $2}' : extrait le deuxième champ (séparetur = virgule)
  HV=$(grep -v '^#' "$ARCHIVE_FILE_SHA256" | grep -v '^%%%%' | awk -F',' '{print $2}')
  log_info "🔐 Valeur ARCHIVE_FILE_SHA256 : $HV"
else
  log_error "Erreur lors de la Création du SHA256 de l'archive."
  exit 1
fi


# -----------------------------------------------------------------------------
# Gestion de l'historisation des archives
# -----------------------------------------------------------------------------
log_info "Gestion de l'historisation des archives."

SECOND_LAST_ARCHIVE=""
SECOND_LAST_ARCHIVE_SHA256=""

# Recherche l'avant dernière archive existante.
# Récupère tous les fichiers .tar.gz triés par nom (timestamp implicite)
mapfile -t archives < <(ls -1 "$ARCHIVE_DIR"/*.tar.gz 2>/dev/null | sort)

# Vérifie qu'il y a au moins deux fichiers
if [ "${#archives[@]}" -ge 2 ]; then
  SECOND_LAST_ARCHIVE="${archives[-2]}"
  SECOND_LAST_ARCHIVE_SHA256="${SECOND_LAST_ARCHIVE}.sha256.txt"
else
  SECOND_LAST_ARCHIVE=""
fi

if [[ -n "$SECOND_LAST_ARCHIVE" ]]; then
  log_info "Avant dernière archive trouvée : $SECOND_LAST_ARCHIVE"
  log_info "SHA256 de l'avant dernière archive trouvée : $SECOND_LAST_ARCHIVE_SHA256"

  ARCHIVE_HASH=$(grep -v '^#' "$ARCHIVE_FILE_SHA256" | grep -v '^%%%%' | awk -F',' '{print $2}' | head -n 1)
  SECOND_LAST_ARCHIVE_HASH=$(grep -v '^#' "$SECOND_LAST_ARCHIVE_SHA256" | grep -v '^%%%%' | awk -F',' '{print $2}' | head -n 1)

  log_info "🔐 SECOND_LAST_ARCHIVE_HASH: $SECOND_LAST_ARCHIVE_HASH"

  if [[ "$ARCHIVE_HASH" == "$SECOND_LAST_ARCHIVE_HASH" ]]; then
    log_info "Les archives sont identiques. Suppression de la dernière archive inutile."
    rm -f "$ARCHIVE_FILE" "$ARCHIVE_FILE_SHA256"
    log_info "Suppression de $ARCHIVE_FILE"
    log_info "Suppression de $ARCHIVE_FILE_SHA256"
  else
    log_info "🔄 Des modifications ont été détectées. La nouvelle archive est conservée."
  fi
else
  log_info "⚠️ Aucune avant-dernière archive trouvée."
fi


# -----------------------------------------------------------------------------
# Fin du script
# -----------------------------------------------------------------------------
log_info "Toutes les étapes de sauvegarde ont été exécutées."
log_success "Script terminé."
exit 0
