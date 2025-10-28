#!/usr/bin/env python3

import re
import sys
import curses

def extract_functions_with_comments(content):
    """
    Extrait les fonctions et leurs commentaires inline.
    """
    pattern = re.compile(
        r'^(?:function\s+)?([a-zA-Z0-9_]+)\s*\(\s*\)\s*\{\s*(?:#\s*(.*))?',
        re.MULTILINE
    )
    return pattern.findall(content)

def display_function_list(stdscr, script_path, functions):
    curses.curs_set(0)
    curses.start_color()
    curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_CYAN)
    stdscr.clear()

    stdscr.addstr(0, 0, f"📜 Fonctions trouvées dans '{script_path}'", curses.A_BOLD)
    stdscr.addstr(1, 0, "-" * (len(script_path) + 30))

    if not functions:
        stdscr.addstr(3, 2, "Aucune fonction trouvée.")
    else:
        # Trouver la longueur maximale du nom de fonction
        max_len = max(len(name) for name, _ in functions)
        padding = 4  # espace entre nom et commentaire

        for idx, (name, comment) in enumerate(functions):
            line = f"• {name.ljust(max_len)}{' ' * padding}"
            if comment:
                line += f"{comment.strip()}"
            stdscr.addstr(idx + 3, 2, line)

    stdscr.addstr(curses.LINES - 2, 0, "Appuyez sur une touche pour quitter.")
    stdscr.refresh()
    stdscr.getch()

def main_curses(stdscr, script_path):
    try:
        with open(script_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        stdscr.addstr(0, 0, f"Erreur : le fichier '{script_path}' n'existe pas.")
        stdscr.refresh()
        stdscr.getch()
        return

    functions = extract_functions_with_comments(content)
    display_function_list(stdscr, script_path, functions)

def main():
    args = sys.argv[1:]
    if len(args) < 1:
        print("Erreur : veuillez fournir le chemin du script.")
        print("Utilisation : python3 func_finder.py <chemin_du_script>")
        sys.exit(1)

    script_path = args[0]
    curses.wrapper(main_curses, script_path)

if __name__ == "__main__":
    main()
