#!/usr/bin/env bash
################################################################################
# install_proton_vpn.sh
#
# Description :
# Ce module installe le client Proton VPN pour l'environnement de bureau GNOME
# en utilisant le script d'installation officiel.
# - Vérifie si Proton VPN est déjà installé.
# - Exécute le script d'installation officiel de Proton.
# - Valide l'installation.
#
# Auteur : Alan MARCHAND
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

################################################################################
# install_proton_vpn : Installe Proton VPN
################################################################################
install_proton_vpn() {
  log_info "Initialisation de l'installation de Proton VPN."

  # 1. Vérification de présence (rend le script idempotent)
  if command -v protonvpn &>/dev/null; then
    log_info "  [STATUT] Proton VPN est déjà installé. Aucune action requise."
    return 0
  fi

  # 2. Exécution du script d'installation officiel
  log_info "  [ACTION] Lancement du script d'installation officiel de Proton VPN..."
  local install_script_url="https://repo.protonvpn.com/debian/install.sh"

  if ! curl -fsSL "${install_script_url}" | bash; then
    log_error "Échec de l'exécution du script d'installation de Proton VPN."
    return 1
  fi

  # 3. Vérification finale
  if command -v protonvpn &>/dev/null; then
    log_info "[SUCCÈS] Proton VPN a été installé avec succès."
    return 0
  else
    log_error "Installation de Proton VPN échouée. Le binaire 'protonvpn' est introuvable."
    return 1
  fi
}
