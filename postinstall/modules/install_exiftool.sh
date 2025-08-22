#!/usr/bin/env bash
################################################################################
# install_exiftool.sh
#
# Description :
# Ce module installe l’outil ExifTool depuis le site officiel en tant que module Perl :
# - Vérifie si ExifTool est déjà installé et à la bonne version
# - Détermine la version cible à partir de l'URL de téléchargement
# - Télécharge et extrait l'archive tar.gz
# - Utilise "perl Makefile.PL", "make" et "make install" pour une installation propre
# - Nettoie le fichier temporaire et valide l’installation
#
# Auteur : Alan MARCHAND (Adaptation par Gemini)
#
# Usage :
# Ce script doit être sourcé depuis un script principal.
################################################################################

# -----------------------------------------------------------------------------
# Vérification : ce module doit être sourcé, pas exécuté directement
# -----------------------------------------------------------------------------
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && {
  echo "Ce script doit être sourcé, pas exécuté directement." >&2
  return 1 2>/dev/null || exit 1
}

# --- Fonctions de log (à définir dans votre script principal si elles ne le sont pas) ---
# Si vous n'avez pas de fonctions log_info, log_error, log_warning,
# vous pouvez les définir simplement comme ceci pour ce script :
log_info() { echo -e "\e[32mINFO:\e[0m $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_error() { echo -e "\e[31mERROR:\e[0m $(date '+%Y-%m-%d %H:%M:%S') $1"; }
log_warning() { echo -e "\e[33mWARNING:\e[0m $(date '+%Y-%m-%d %H:%M:%S') $1"; }
# ---------------------------------------------------------------------------------------

################################################################################
# install_exiftool : Installe ExifTool
################################################################################
install_exiftool() {
  log_info "[INSTALLATION] Initialisation de l'installation d'ExifTool."

  # L'URL du fichier d'archive d'ExifTool.
  # Veuillez la mettre à jour manuellement si une nouvelle version est disponible sur exiftool.org.
  local EXIFTOOL_DOWNLOAD_URL="https://exiftool.org/Image-ExifTool-13.33.tar.gz"
  local ARCHIVE_NAME=$(basename "${EXIFTOOL_DOWNLOAD_URL}") # Ex: Image-ExifTool-13.33.tar.gz
  # Extrait la version (ex: 13.33) du nom de l'archive
  local EXPECTED_EXIFTOOL_VERSION=$(echo "${ARCHIVE_NAME}" | sed -E 's/Image-ExifTool-([0-9.]+)\.tar\.gz/\1/')

  if [ -z "${EXPECTED_EXIFTOOL_VERSION}" ]; then
    log_error "Impossible de déterminer la version attendue à partir de l'URL de téléchargement : ${EXIFTOOL_DOWNLOAD_URL}"
    return 1
  fi

  # 1. Vérification de présence et de version pour l'idempotence
  log_info "  [STATUT] Vérification de la version d'ExifTool actuellement installée..."
  if command -v exiftool &>/dev/null; then
    local current_exiftool_version
    # Capture la version et redirige stderr vers /dev/null pour éviter des messages d'erreur si exiftool est cassé
    current_exiftool_version=$(exiftool -ver 2>/dev/null)
    if [ "$?" -eq 0 ] && [ "${current_exiftool_version}" = "${EXPECTED_EXIFTOOL_VERSION}" ]; then
      log_info "  [STATUT] ExifTool version ${EXPECTED_EXIFTOOL_VERSION} est déjà installée et à jour."
      return 0 # ExifTool est déjà là et à la bonne version, le script s'arrête ici.
    else
      log_warning "  [STATUT] ExifTool trouvé (version : ${current_exiftool_version:-N/A}) mais ne correspond pas à la version attendue (${EXPECTED_EXIFTOOL_VERSION}). Procédure de mise à jour/réinstallation lancée."
    fi
  else
    log_info "  [STATUT] ExifTool n'est pas trouvé dans le PATH. Procédure d'installation lancée."
  fi

  # 2. Vérification et installation des dépendances système (wget, tar, make, perl-modules)
  log_info "  [ACTION] Vérification et installation des dépendances système (wget, tar, make, perl-modules)..."
  # Dépendances pour le téléchargement et l'extraction
  for pkg in wget tar; do
    if ! command -v "$pkg" &>/dev/null; then
      log_info "  [DÉPENDANCE] '$pkg' non trouvé. Tentative d'installation..."
      sudo apt update >/dev/null 2>&1 || sudo yum check-update >/dev/null 2>&1 || log_warning "Impossible de mettre à jour les paquets."
      if command -v apt &>/dev/null; then sudo apt install -y "$pkg";
      elif command -v yum &>/dev/null; then sudo yum install -y "$pkg";
      else log_error "Impossible d'installer '$pkg'. Veuillez l'installer manuellement."; return 1; fi
      if ! command -v "$pkg" &>/dev/null; then log_error "Échec de l'installation de '$pkg'."; return 1; fi
    fi
  done

  # Dépendances pour la compilation et l'installation de modules Perl
  if ! command -v make &>/dev/null; then
    log_info "  [DÉPENDANCE] 'make' non trouvé. Tentative d'installation..."
    sudo apt update >/dev/null 2>&1 || sudo yum check-update >/dev/null 2>&1 || log_warning "Impossible de mettre à jour les paquets."
    if command -v apt &>/dev/null; then sudo apt install -y make;
    elif command -v yum &>/dev/null; then sudo yum install -y make;
    else log_error "Impossible d'installer 'make'. Veuillez l'installer manuellement."; return 1; fi
    if ! command -v make &>/dev/null; then log_error "Échec de l'installation de 'make'."; return 1; fi
  fi

  # Paquets pour les outils de développement Perl (essentiels pour 'Makefile.PL')
  if command -v apt &>/dev/null; then
      # Vérifie si un des paquets perl-modules ou perl-base est installé
      if ! dpkg -s perl-modules >/dev/null 2>&1 && ! dpkg -s perl-base >/dev/null 2>&1; then
          log_info "  [DÉPENDANCE] Paquets Perl de base (perl-modules/perl-base) non trouvés. Tentative d'installation..."
          sudo apt install -y perl-modules perl-base || log_warning "Impossible d'installer perl-modules/perl-base. L'installation d'ExifTool pourrait échouer."
      fi
  elif command -v yum &>/dev/null; then
      # Vérifie si le paquet perl-devel est installé
      if ! rpm -q perl-devel >/dev/null 2>&1; then
          log_info "  [DÉPENDANCE] Paquet perl-devel non trouvé. Tentative d'installation..."
          sudo yum install -y perl-devel || log_warning "Impossible d'installer perl-devel. L'installation d'ExifTool pourrait échouer."
      fi
  fi
  log_info "  [INFO] Toutes les dépendances vérifiées."

  # 3. Création du répertoire temporaire
  local temp_dir
  temp_dir=$(mktemp -d -t exiftool_install_XXXXXX)
  if [ $? -ne 0 ]; then
    log_error "Impossible de créer un répertoire temporaire."
    return 1
  fi
  log_info "  [INFO] Répertoire temporaire créé : ${temp_dir}"

  # 4. Téléchargement de l’archive
  log_info "  [ACTION] Téléchargement d'ExifTool depuis : ${EXIFTOOL_DOWNLOAD_URL}"
  if ! wget -q --show-progress "${EXIFTOOL_DOWNLOAD_URL}" -O "${temp_dir}/${ARCHIVE_NAME}"; then
    log_error "Échec du téléchargement d'ExifTool."
    rm -rf "${temp_dir}"
    return 1
  fi

  # 5. Extraction de l'archive
  log_info "  [ACTION] Extraction de l'archive vers ${temp_dir}"
  local EXTRACTED_DIR=$(echo "${ARCHIVE_NAME}" | sed -E 's/\.tar\.gz$//')
  if ! tar -xzf "${temp_dir}/${ARCHIVE_NAME}" -C "${temp_dir}"; then
    log_error "Échec de l'extraction de l'archive ExifTool."
    rm -rf "${temp_dir}"
    return 1
  fi

  # 6. Installation des modules Perl et de l'exécutable
  log_info "  [ACTION] Installation des modules Perl d'ExifTool via 'make install'..."
  # Changer de répertoire dans le dossier extrait pour l'installation Perl
  cd "${temp_dir}/${EXTRACTED_DIR}" || { log_error "Impossible de changer de répertoire vers ${temp_dir}/${EXTRACTED_DIR}"; rm -rf "${temp_dir}"; return 1; }

  # Exécuter les commandes Perl standard pour l'installation des modules
  if ! perl Makefile.PL INSTALL_BASE=/usr/local ; then # Crée le Makefile
    # INSTALL_BASE=/usr/local assure que les fichiers sont installés dans des chemins comme /usr/local/bin et /usr/local/share/perl
    log_error "Échec de l'exécution de 'perl Makefile.PL'. Vérifiez que Perl est correctement installé et que les dépendances (make, perl-devel) sont présentes."
    rm -rf "${temp_dir}"
    return 1
  fi
  if ! make ; then # Construit les modules
    log_error "Échec de l'exécution de 'make'. Un problème est survenu lors de la compilation des modules."
    rm -rf "${temp_dir}"
    return 1
  fi
  if ! sudo make install ; then # Installe les modules et le binaire dans les chemins systèmes
    log_error "Échec de l'exécution de 'sudo make install'. Cela peut indiquer un problème de permissions ou une corruption de l'installation Perl."
    rm -rf "${temp_dir}"
    return 1
  fi

  log_info "  [INFO] Installation des modules Perl d'ExifTool terminée."

  # 7. Nettoyage
  log_info "  [ACTION] Nettoyage des fichiers temporaires."
  rm -rf "${temp_dir}"

  # 8. Vérification finale de l'installation
  log_info "--- Vérification finale de l'installation d'ExifTool ---"
  if command -v exiftool &>/dev/null; then
    local final_version
    final_version=$(exiftool -ver 2>/dev/null)
    if [ "$?" -eq 0 ] && [ "${final_version}" = "${EXPECTED_EXIFTOOL_VERSION}" ]; then
        log_info "[SUCCÈS] ExifTool installé avec succès (version : ${final_version})."
        return 0
    else
        log_error "ExifTool est installé (version : ${final_version}), mais ne correspond pas à la version attendue (${EXPECTED_EXIFTOOL_VERSION})."
        log_error "Vérifiez l'URL de téléchargement ou la version attendue dans le script."
        return 1
    fi
  else
    log_error "ExifTool n'a pas pu être trouvé dans le PATH après l'installation."
    log_error "Cela indique probablement un échec lors de 'make install' ou un problème avec votre PATH."
    return 1
  fi
}
