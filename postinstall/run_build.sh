#!/usr/bin/env bash
################################################################################
# run_build.sh
#
# Description :
# Lance le script de post-installation build.sh avec journalisation.
# - Génère un fichier de log horodaté dans /tmp
# - Préserve les variables d’environnement (comme DEBUG)
# - Vérifie la présence de build.sh avant exécution
#
# Auteur : Alan MARCHAND
################################################################################

# -----------------------------------------------------------------------------
# Initialisation du fichier de log
# -----------------------------------------------------------------------------
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
log_file="/var/log/debug_build_ubuntu_${timestamp}.log"
echo "▶ Lancement de build.sh et enregistrement de la session dans ${log_file}"

# -----------------------------------------------------------------------------
# Vérification : build.sh doit être présent et exécutable
# -----------------------------------------------------------------------------
if [[ ! -x ./build.sh ]]; then
  echo "❌ Le fichier ./build.sh est introuvable ou non exécutable." >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Exécution du script avec journalisation
# -----------------------------------------------------------------------------
# Préserve les variables d’environnement, y compris DEBUG=true si présent
export CALLER_SCRIPT="run_build.sh"
sudo -E ./build.sh 2>&1 | sudo tee "${log_file}"
exit_code="${PIPESTATUS[0]}"

# -----------------------------------------------------------------------------
# Résultat final
# -----------------------------------------------------------------------------
if [[ "${exit_code}" -eq 0 ]]; then
  echo "✅ Script terminé avec succès."
else
  echo "⚠️  Script terminé avec des erreurs. Voir le fichier log : ${log_file}"
fi

exit "${exit_code}"
