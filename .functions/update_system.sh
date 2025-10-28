#!/usr/bin/env bash


echo "🔄 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
sudo snap refresh


# Charger la fonction upgrade_oh_my_bash
if [ -f "$HOME/.oh-my-bash/tools/upgrade.sh" ]; then
  source "$HOME/.oh-my-bash/tools/upgrade.sh"
  #upgrade_oh_my_bash
else
  echo "⚠️ Impossible de tsourcer upgrade_oh_my_bash"
fi

echo "✅ Mise à jour terminée !"
