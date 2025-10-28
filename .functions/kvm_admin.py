import curses
import subprocess
import re
import shutil

MAX_VMS = 99

def get_vm_list():
    """
    Récupère la liste des noms de toutes les machines virtuelles KVM.

    Utilise la commande 'virsh list --all --name' pour obtenir les noms
    des VMs, qu'elles soient en cours d'exécution ou arrêtées.

    Returns:
        list[str]: Liste des noms de VM.
    """
    try:
        output = subprocess.check_output(
            ['virsh', 'list', '--all', '--name'], text=True
        )
        return [line.strip() for line in output.splitlines() if line.strip()]
    except subprocess.CalledProcessError:
        return []

def get_vm_state(vm_name):
    """
    Récupère l'état actuel d'une VM donnée (ex: running, shut off).

    Args:
        vm_name (str): Nom de la machine virtuelle.

    Returns:
        str: État de la VM ou "unknown" en cas d'erreur.
    """
    try:
        return subprocess.check_output(
            ['virsh', 'domstate', vm_name], text=True
        ).strip()
    except subprocess.CalledProcessError:
        return "unknown"

def get_mac_address(vm_name):
    """
    Récupère l'adresse MAC de l'interface réseau principale de la VM.

    Args:
        vm_name (str): Nom de la machine virtuelle.

    Returns:
        str or None: Adresse MAC ou None si introuvable.
    """
    try:
        output = subprocess.check_output(
            ['virsh', 'domiflist', vm_name], text=True
        )
        for line in output.splitlines():
            if 'vnet' in line:
                return line.split()[4]
    except subprocess.CalledProcessError:
        pass
    return None

def get_ip_address(mac):
    """
    Tente de retrouver l'adresse IP associée à une adresse MAC.

    Utilise les commandes 'arp -an' et 'ip neigh' pour interroger
    la table ARP locale.

    Args:
        mac (str): Adresse MAC.

    Returns:
        str: Adresse IP ou "Unknown"/"N/A" si non trouvée.
    """
    if not mac:
        return "N/A"
    try:
        arp_output = subprocess.check_output(['arp', '-an'], text=True)
        match = re.search(rf'\(([\d.]+)\).*{mac}', arp_output)
        if match:
            return match.group(1)
    except Exception:
        pass
    try:
        ip_output = subprocess.check_output(['ip', 'neigh'], text=True)
        for line in ip_output.splitlines():
            if mac in line:
                return line.split()[0]
    except Exception:
        pass
    return "Unknown"

def get_vm_info():
    """
    Compile les informations principales de chaque VM.

    Pour chaque VM, récupère son état, son IP (si active),
    et les actions disponibles.

    Returns:
        list[dict]: Liste de dictionnaires contenant les infos VM.
    """
    vm_data = []
    vm_list = get_vm_list()
    for idx, vm_name in enumerate(vm_list[:MAX_VMS], start=1):
        state = get_vm_state(vm_name)
        mac = get_mac_address(vm_name)
        ip = get_ip_address(mac) if state == "running" else "N/A"
        action = "Arrêter" if state == "running" else "Démarrer" \
            if state == "shut off" else "N/A"
        extra = "Cloner / Supprimer" if state == "shut off" else "Cloner"
        vm_data.append({
            "id": idx,
            "name": vm_name,
            "state": state,
            "ip": ip,
            "action": action,
            "extra": extra
        })
    return vm_data

def apply_action(vm_name, action):
    """
    Démarre ou arrête une VM selon l'action spécifiée.

    Args:
        vm_name (str): Nom de la VM.
        action (str): "Démarrer" ou "Arrêter".
    """
    if action == "Démarrer":
        subprocess.run(['virsh', 'start', vm_name])
    elif action == "Arrêter":
        subprocess.run(['virsh', 'shutdown', vm_name])

def clone_vm(stdscr, vm_name):
    """
    Clone une VM existante en demandant un nouveau nom à l'utilisateur.

    Args:
        stdscr: Fenêtre curses pour affichage.
        vm_name (str): Nom de la VM à cloner.
    """
    curses.echo()
    stdscr.clear()
    stdscr.addstr(0, 0, "🧬 Nom de la nouvelle VM à créer : ")
    stdscr.refresh()
    new_name = stdscr.getstr(1, 0, 40).decode().strip()
    curses.noecho()

    if not new_name:
        return

    if new_name in get_vm_list():
        stdscr.addstr(3, 0, "❌ Ce nom existe déjà.")
        stdscr.getch()
        return

    if get_vm_state(vm_name) == "running":
        stdscr.addstr(3, 0, "⚠️ VM en cours. Veuillez l'arrêter d'abord.")
        stdscr.getch()
        return

    stdscr.clear()
    stdscr.addstr(0, 0, f"🔄 Clonage de '{vm_name}' vers '{new_name}'...")
    stdscr.refresh()

    result = subprocess.run([
        'virt-clone', '--original', vm_name,
        '--name', new_name, '--auto-clone'
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    stdscr.clear()
    if result.returncode == 0:
        stdscr.addstr(0, 0, "✅ Clonage réussi !")
        stdscr.addstr(2, 0, f"🧬 Le clone « {new_name} » a été créé.")
    else:
        stdscr.addstr(0, 0, "❌ Échec du clonage.")
        stdscr.addstr(2, 0, result.stderr.strip())

    stdscr.addstr(4, 0, "Appuyez sur une touche pour continuer.")
    stdscr.refresh()
    stdscr.getch()

def delete_vm(stdscr, vm_name):
    """
    Supprime une VM arrêtée ainsi que son stockage.

    Args:
        stdscr: Fenêtre curses pour affichage.
        vm_name (str): Nom de la VM à supprimer.
    """
    stdscr.clear()
    stdscr.addstr(0, 0, f"🗑️ Suppression de la VM '{vm_name}'...")
    stdscr.refresh()

    if get_vm_state(vm_name) == "running":
        stdscr.addstr(2, 0, "⚠️ VM en cours. Veuillez l'arrêter d'abord.")
        stdscr.addstr(4, 0, "Appuyez sur une touche pour revenir.")
        stdscr.getch()
        return

    result = subprocess.run([
        'virsh', 'undefine', vm_name, '--remove-all-storage'
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    stdscr.clear()
    if result.returncode == 0:
        stdscr.addstr(0, 0, f"✅ VM '{vm_name}' supprimée.")
    else:
        stdscr.addstr(0, 0, f"❌ Échec de la suppression.")
        stdscr.addstr(2, 0, result.stderr.strip())

    stdscr.addstr(4, 0, "Appuyez sur une touche pour continuer.")
    stdscr.refresh()
    stdscr.getch()

def draw_menu(stdscr, vm_data, selected_idx):
    """
    Affiche le menu principal avec la liste des VMs.

    Args:
        stdscr: Fenêtre curses pour affichage.
        vm_data (list): Liste des infos VM.
        selected_idx (int): Index de la VM sélectionnée.
    """
    stdscr.clear()
    stdscr.addstr(0, 2, "🖥️  Gestion des machines virtuelles KVM",
                   curses.A_BOLD)
    stdscr.addstr(1, 0, "-" * 80)
    stdscr.addstr(2, 0, f"{'ID':<3} {'Nom VM':<25} {'État':<10} "
                        f"{'IP':<15} {'Action':<10}")
    stdscr.addstr(3, 0, "-" * 80)

    for i, vm in enumerate(vm_data):
        highlight = curses.A_REVERSE if i == selected_idx else curses.A_NORMAL
        stdscr.addstr(
            4 + i, 0,
            f"{vm['id']:<3} {vm['name']:<25} {vm['state']:<10} "
            f"{vm['ip']:<15} {vm['action']:<10}",
            highlight
        )

    stdscr.addstr(
        5 + len(vm_data), 0,
        "↑ ↓ : naviguer   Entrée : action principale   "
        "c : cloner   d : supprimer   r : rafraîchir   q : quitter"
    )
    stdscr.refresh()

def main(stdscr):
    """
    Fonction principale exécutée dans l'interface curses.

    Elle initialise l'affichage, vérifie les dépendances,
    puis gère les interactions clavier pour naviguer et
    effectuer des actions sur les VMs.
    """
    curses.curs_set(0)

    if not shutil.which("virsh"):
        stdscr.addstr(0, 0, "❌ virsh n'est pas installé.")
        stdscr.addstr(
            2, 0,
            "Installez-le avec : sudo apt install libvirt-clients"
        )
        stdscr.refresh()
        stdscr.getch()
        return

    vm_data = get_vm_info()
    if not vm_data:
        stdscr.addstr(0, 0, "⚠️ Aucune machine virtuelle détectée.")
        stdscr.addstr(
            2, 0,
            "Créez une VM avec virt-manager ou virt-install."
        )
        stdscr.refresh()
        stdscr.getch()
        return

    selected_idx = 0

    while True:
        draw_menu(stdscr, vm_data, selected_idx)
        key = stdscr.getch()

        if key == curses.KEY_UP and selected_idx > 0:
            selected_idx -= 1
        elif key == curses.KEY_DOWN and selected_idx < len(vm_data) - 1:
            selected_idx += 1
        elif key in [ord('\n'), curses.KEY_ENTER]:
            vm = vm_data[selected_idx]
            apply_action(vm['name'], vm['action'])
            vm_data = get_vm_info()
        elif key in [ord('r'), ord('R')]:
            vm_data = get_vm_info()
        elif key in [ord('c'), ord('C')]:
            vm = vm_data[selected_idx]
            clone_vm(stdscr, vm['name'])
            vm_data = get_vm_info()
        elif key in [ord('d'), ord('D')]:
            vm = vm_data[selected_idx]
            delete_vm(stdscr, vm['name'])
            vm_data = get_vm_info()
        elif key in [ord('q'), ord('Q')]:
            break

if __name__ == "__main__":
    curses.wrapper(main)
