# Scripts Alan

## 📦 Structure

- `jobs/`    : Scripts principaux orchestrateurs (ex. postinstall, backup)
- `modules/` : Modules unitaires spécialisés (install, update, cleanup)
- `lib/`     : Fonctions utilitaires partagées (log, vérifications, etc.)
- `config/`  : Fichiers de configuration (.list, .deb, etc.)
- `assets/`  : Fichiers statiques (polices, binaires, etc.)
- `logs/`    : Fichiers de log générés automatiquement
- `firefox/` : Scripts liés à Firefox (cookies, exceptions)
- `kvm/`     : Scripts de gestion de machines virtuelles
- `python/`  : Scripts Bash liés à Python ou à des environnements virtuels
- `docs/`    : Documentation du projet

## 🚀 Utilisation

```bash
make run-postinstall
make backup-drive

## 🛠️  Dépendances

- Bash ≥ 5.0
- Rclone (pour les sauvegardes)
- Git (pour le versionnement)
- Sudo (pour les scripts système)
