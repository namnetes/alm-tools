import os
import re
import argparse


def renommer_images(prefix):
    # Nettoie le préfixe pour enlever les caractères indésirables à la fin
    prefix = re.sub(r'[-_.]$', '', prefix)

    # Extensions d'images supportées (triées)
    extensions = sorted([
        "bmp", "gif", "jpeg", "jpg", "mp4", "png", "tif", "tiff", "webm", "webp"
    ])

    # Liste des fichiers images dans le dossier courant
    files = [
        f for f in os.listdir('.')
        if (
            os.path.isfile(f)
            and not f.startswith('.')
            and f.lower().split('.')[-1] in extensions
            and f != os.path.basename(__file__)
        )
    ]

    total = len(files)
    digits = len(str(total))  # Nombre de chiffres pour le padding

    for i, file in enumerate(sorted(files), start=1):
        ext = file.split('.')[-1]
        # Nouveau nom avec préfixe et numéro
        newname = f"{prefix}_{str(i).zfill(digits)}.{ext}"
        if os.path.exists(newname):
            print(f"Attention: {newname} existe déjà, saut du fichier {file}")
            continue
        os.rename(file, newname)
        print(f"{file} -> {newname}")


if __name__ == "__main__":
    # Argument parser pour le préfixe
    parser = argparse.ArgumentParser(
        description=(
            "Renomme les images du dossier courant en utilisant le format "
            "'<préfixe>_<numéro>'. Exemple : monprefix_01.jpg"
        )
    )
    parser.add_argument(
        "prefix", help="Préfixe pour les nouveaux noms de fichiers"
    )
    args = parser.parse_args()
    renommer_images(args.prefix)
