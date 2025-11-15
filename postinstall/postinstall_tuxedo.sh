#!/bin/bash
# Nettoyage des langues étrangères et logiciels inutiles
# Chaque ligne <= 80 caractères

set -euo pipefail

# Paquets à supprimer (langues + logiciels inutiles)
REMOVE_PKGS="
gnome-user-docs-de
hunspell-de-at-frami
hunspell-de-ch-frami
hunspell-de-de-frami
hunspell-en-au
hunspell-en-ca
hunspell-en-gb
hunspell-en-za
hyphen-en-ca
ibus-table-cangjie-big
ibus-table-cangjie3
ibus-table-cangjie5
language-pack-de
language-pack-de-base
language-pack-gnome-de
language-pack-gnome-de-base
libchewing3
libchewing3-data
libmarisa0
libm17n-0
libopencc1.1
libopencc-data
libotf1
libpinyin15
libpinyin-data
libreoffice-help-de
libreoffice-help-en-gb
libreoffice-help-en-us
m17n-db
mythes-de-ch
mythes-en-au
thunderbird
virtualbox
virtualbox-guest-additions-iso
wngerman
wogerman
wswiss
"

# Paquets à installer (FR + EN-US)
INSTALL_PKGS="
aspell-fr
hunspell-en-us
hunspell-fr
hyphen-en-us
hyphen-fr
language-pack-fr
language-pack-fr-base
language-pack-gnome-fr
language-pack-gnome-fr-base
"

echo "Suppression des paquets étrangers et inutiles..."
sudo apt remove --purge -y $REMOVE_PKGS || true
sudo apt remove --purge -y libreoffice* || true

echo "Suppression complète des paquets..."
sudo apt autoremove --purge -y
sudo apt clean

echo "Suppression des fichiers de configuration résiduels..."
for app in $REMOVE_PKGS libreoffice; do
  rm -rf ~/.cache/$app ~/.config/$app ~/.local/share/$app 2>/dev/null || true
done

echo "Suppression du répertoire VirtualBox VMs..."
rm -rf ~/VirtualBox\ VMs 2>/dev/null || true

echo "Installation des paquets FR + EN-US..."
sudo apt install -y $INSTALL_PKGS

echo "Configuration terminée."
