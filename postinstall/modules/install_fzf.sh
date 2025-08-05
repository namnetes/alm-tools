#!/usr/bin/env bash
################################################################################
# install_fzf.sh
#
# Description :
# Ce module installe l’outil fzf (fuzzy finder) depuis GitHub :
# - Vérifie si fzf est déjà installé (n'importe où dans le PATH).
# - Si oui, il considère l'installation réussie et s'arrête.
# - Sinon, il récupère la dernière version depuis l’API GitHub,
#   télécharge l'archive tar.gz, extrait le binaire, et l'installe
#   dans /usr/local/bin.
# - Nettoie le fichier temporaire et valide l’installation.
#
# Auteur : Gemini (réécrit d'après le modèle d'Alan MARCHAND)
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

# Assurez-vous d'avoir ces fonctions de log définies dans common.sh ou ici :
# log_info() { echo "[INFO] $1"; }
# log_error() { echo "[ERREUR] $1" >&2; }
# log_debug() { echo "[DEBUG] $1"; }
# log_success() { echo "[SUCCÈS] $1"; }
# log_warning() { echo "[AVERTISSEMENT] $1"; }

################################################################################
# install_fzf : Installe fzf (fuzzy finder)
################################################################################
install_fzf() {
  log_info "[INSTALLATION] Initialisation de fzf (fuzzy finder)."

  local fzf_target="/usr/local/bin/fzf" # Emplacement où ce script installerait fzf si nécessaire

  local fzf_current_path # Chemin de l'exécutable fzf s'il est trouvé dans PATH
  fzf_current_path=$(command -v fzf 2>/dev/null)
  local current_fzf_version=""

  # 1. Vérification si fzf est déjà installé (n'importe où dans le PATH)
  if [ -n "${fzf_current_path}" ]; then
      current_fzf_version=$("${fzf_current_path}" --version 2>/dev/null | head -n 1 | awk '{print $1}')
      log_info "  [STATUT] fzf est déjà trouvé dans le PATH (${fzf_current_path}). Version : ${current_fzf_version}."
      log_info "  Considérant fzf comme installé. Aucune action supplémentaire requise."
      return 0 # Sortie réussie car fzf est déjà disponible.
  else
      log_info "  [STATUT] fzf non trouvé dans le PATH. Procédure d'installation initiale."
  fi

  # 2. Vérification des dépendances (uniquement si fzf n'est pas déjà là)
  if ! command -v curl &> /dev/null; then
      log_error "Dépendance manquante : 'curl'. Veuillez l'installer."
      return 1
  fi
  # Re-activation de la vérification de 'tar' puisque nous utilisons une archive .tar.gz
  if ! command -v tar &> /dev/null; then
      log_error "Dépendance manquante : 'tar'. Veuillez l'installer."
      return 1
  fi
  if ! command -v gzip &> /dev/null; then
      log_warning "gzip n'est pas trouvé. Tar peut encore fonctionner avec l'option -z, mais il est recommandé de l'installer."
  fi

  local latest_fzf_version
  # 3. Récupération de la dernière version depuis GitHub API
  log_info "  [ACTION] Récupération de la dernière version de fzf depuis GitHub..."
  latest_fzf_version=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "\K[^"]*')

  if [ -z "${latest_fzf_version}" ]; then
    log_error "Impossible de récupérer la dernière version de fzf depuis GitHub. Vérifiez votre connexion ou l'API GitHub."
    return 1
  fi
  log_info "  [INFO] Dernière version disponible : ${latest_fzf_version}"

  log_info "  [INFO] Préparation à l'installation de fzf à la version ${latest_fzf_version} dans ${fzf_target}."

  # 4. Téléchargement de l’archive .tar.gz
  # Extraction du numéro de version sans le 'v' initial pour le nom du fichier
  local version_without_v="${latest_fzf_version#v}" # Supprime le 'v' initial
  local fzf_archive_name="fzf-${version_without_v}-linux_amd64.tar.gz" # <-- NOM DE FICHIER CORRIGÉ
  local download_url="https://github.com/junegunn/fzf/releases/download/${latest_fzf_version}/${fzf_archive_name}" # <-- URL CORRIGÉE

  local temp_tar
  temp_tar=$(mktemp --suffix=.tar.gz)

  log_info "  [ACTION] Téléchargement de l'archive depuis : ${download_url}"
  if ! curl -fsSL "${download_url}" -o "${temp_tar}"; then
    log_error "Échec du téléchargement de fzf depuis GitHub. L'URL pourrait être invalide ou il y a un problème réseau (Erreur 404 probable)."
    rm -f "${temp_tar}"
    return 1
  fi

  # Vérification que le fichier téléchargé n'est pas vide ou corrompu
  if [ ! -s "${temp_tar}" ]; then
      log_error "L'archive téléchargée est vide ou corrompue. URL : ${download_url}"
      rm -f "${temp_tar}"
      return 1
  fi

  # 5. Extraction vers /usr/local/bin
  log_info "  [ACTION] Extraction du binaire vers ${fzf_target}"
  if [ ! -d "$(dirname "${fzf_target}")" ]; then
    log_info "  [ACTION] Création du répertoire $(dirname "${fzf_target}")..."
    sudo mkdir -p "$(dirname "${fzf_target}")" || { log_error "Impossible de créer $(dirname "${fzf_target}"). Nécessite des permissions sudo."; rm -f "${temp_tar}"; return 1; }
  fi

  # Utilisation de sudo pour tar, car il écrit dans un répertoire système
  # Ajout du 'z' pour gzip à la commande tar pour la décompression
  if ! sudo tar xzf "${temp_tar}" -C "$(dirname "${fzf_target}")" fzf; then
    log_error "Échec de l’extraction du binaire fzf. L'archive est peut-être corrompue ou un problème de permissions."
    rm -f "${temp_tar}"
    return 1
  fi
  sudo chmod +x "${fzf_target}" # Rendre le binaire exécutable

  # 6. Nettoyage
  rm -f "${temp_tar}"

  # 7. Vérification finale après installation par le script
  if command -v fzf &>/dev/null && [[ "$(command -v fzf)" == "${fzf_target}" ]]; then
    local final_version
    final_version=$("${fzf_target}" --version 2>/dev/null | head -n 1 | awk '{print $1}')
    log_success "[SUCCÈS] fzf installé avec succès (version : ${final_version}) dans ${fzf_target}."
    log_info "  N'oubliez pas d'ajouter l'intégration fzf à votre ~/.bashrc (ou équivalent) si ce n'est pas déjà fait :"
    log_info '    eval "$(fzf --bash)"'
    log_info "  Redémarrez votre terminal ou sourcez votre .bashrc (source ~/.bashrc) pour appliquer les changements."
  else
    log_error "fzf semble mal installé ou introuvable dans ${fzf_target} après l'installation."
    return 1
  fi
}
