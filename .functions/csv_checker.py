"""
Script de vérification de fichiers CSV.

Fonctionnalités :
-----------------
- Utilise -d ou --delimiter pour spécifier le séparateur CSV
  (ex: ',', ';', '|', '\\t').
- Vérifie que toutes les lignes du fichier ont le même nombre
  de colonnes.
- Affiche des messages d’erreur clairs et alignés en cas de
  problème de structure.
- Peut fonctionner en mode silencieux avec -q ou --quiet.
- Offre un mode --strict pour arrêter à la première erreur
  détectée, ou continuer et lister toutes les erreurs.

Exemples d'utilisation :
------------------------
    python verifier_csv.py -f fichier.csv -d ',' --strict
    python verifier_csv.py -f fichier.tsv -d '\\t' -q

Auteur : Magali (modifié avec amour par Copilot 🤖)
"""

import csv
import sys
import os
import argparse


def check_csv_columns(file_path, delimiter, verbose=True, strict=True):
    """
    Vérifie que chaque ligne d'un fichier CSV a le même nombre
    de colonnes.

    Parameters
    ----------
    file_path : str
        Le chemin du fichier CSV à vérifier.
    delimiter : str
        Le délimiteur utilisé dans le fichier CSV.
    verbose : bool, optional
        Si True, affiche les messages de statut (par défaut True).
    strict : bool, optional
        Si True, s'arrête à la première erreur. Sinon, affiche
        toutes les erreurs (par défaut True).

    Returns
    -------
    bool
        True si toutes les lignes ont le même nombre de colonnes,
        False sinon.
    """
    try:
        with open(file_path, mode="r", newline="", encoding="utf-8") as f:
            reader = csv.reader(f, delimiter=delimiter)
            first_row = next(reader)
            num_columns = len(first_row)

            errors = []
            for line_number, row in enumerate(reader, start=2):
                if len(row) != num_columns:
                    if strict:
                        raise ValueError(
                            f"Erreur à la ligne {line_number}: "
                            f"{len(row)} colonnes trouvées."
                        )
                    else:
                        errors.append((line_number, len(row)))

        if errors:
            if verbose:
                print(
                    f"Le fichier '{file_path}' comporte "
                    f"{num_columns} colonnes."
                )
                print("Des erreurs ont été détectées :")
                max_line = max(line for line, _ in errors)
                width = len(str(max_line))
                for line, found in errors:
                    print(
                        f"Erreur à la ligne {str(line).rjust(width)}: "
                        f"{found} colonnes trouvées."
                    )
            return False

        return True

    except ValueError as ve:
        if verbose:
            print(
                f"Le fichier '{file_path}' comporte "
                f"{num_columns} colonnes."
            )
            print(ve)
        return False
    except FileNotFoundError:
        if verbose:
            print(f"Erreur: Le fichier '{file_path}' est introuvable.")
        return False
    except Exception as e:
        if verbose:
            print(f"Une erreur inattendue est survenue: {str(e)}")
        return False


def main():
    """
    Point d'entrée principal du programme. Gère les arguments
    et lance la vérification du fichier CSV.
    """
    parser = argparse.ArgumentParser(
        description="Vérifie que toutes les lignes d’un CSV "
                    "ont le même nombre de colonnes."
    )
    parser.add_argument(
        "-f", "--infile", required=True,
        help="Le chemin du fichier CSV à traiter."
    )
    parser.add_argument(
        "-d", "--delimiter", default=";",
        help="Délimiteur du CSV (ex: ',', ';', '|', '\\t')."
    )
    parser.add_argument(
        "-q", "--quiet", action="store_true",
        help="Mode silencieux (aucune sortie sur la console)."
    )
    parser.add_argument(
        "--strict", action="store_true",
        help="Mode strict : s'arrête à la première erreur."
    )

    args = parser.parse_args()

    if args.delimiter == r"\t":
        args.delimiter = "\t"

    if not os.path.isfile(args.infile):
        if not args.quiet:
            print(f"Erreur: Le fichier '{args.infile}' n'existe pas.")
        sys.exit(1)

    result = check_csv_columns(
        args.infile,
        args.delimiter,
        verbose=not args.quiet,
        strict=args.strict,
    )

    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
