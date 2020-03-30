# Wireguard Configurator Python edition
# This should be your one-stop shop to get Wireguard installed and configured

import os
from pathlib import Path

operatingsystem: str = "Windows"
distribution: str = 'unknown'
wireguardpath: str = Path('.') / "wireguard-test" / "wireguard"
selectedinterface: str = "wg0"


# Main Loop
def wgc():
    clear()
    printlogo()
    mainmenu()


def printlogo():
    print("oooooo   oooooo     oooo   .oooooo.      .oooooo.      ")
    print(" `888.    `888.     .8'   d8P'  `Y8b    d8P'  `Y8b     ")
    print("  `888.   .8888.   .8'   888           888             ")
    print("   `888  .8'`888. .8'    888           888             ")
    print("    `888.8'  `888.8'     888     ooooo 888             ")
    print("     `888'    `888'      `88.    .88'  `88b    ooo     ")
    print("      `8'      `8'        `Y8bood8P'    `Y8bood8P'  .py")
    print("WireGuard Configurator - Python Edition")
    print("")


def askyesno(question, default='n'):
    while "the answer is invalid":
        if default == 'y':
            reply = str(input(question + ' (Y/n): ')).lower().strip()
            if reply[:1] != 'n':
                return True
            else:
                return False
        else:
            reply = str(input(question + ' (y/N): ')).lower().strip()
            if reply[:1] != 'y':
                return False
            else:
                return True


def clear():
    if os.name == 'nt':
        os.system('cls')
    else:
        os.system('clear')


def listfile(path: str, filefilter: str):
    lis: list = []
    for file in os.listdir(path):
        if file.endswith(filefilter):
            lis.append(file)
    return lis


def printlistmenu(lis: list):
    i: int = 0
    for i in range(len(lis)):
        print(str(i) + ": " + str(lis[i]))


def makemenu(title: str, labels: list, commands: list, maxtries: int = 3):
    tries: int = 0
    if int(len(labels)) != int(len(commands)):
        print("There are " + str(len(labels)) + " labels and " + str(len(commands)) + " commands passed in this menu.")
        print("You must pass the same number of commands .")
    while tries < maxtries:
        print("")
        print(title)
        printlistmenu(labels)
        selection: int = int(input("Please select an option [0-" + str(len(labels) - 1) + "]:"))
        if 0 <= selection <= int(len(labels) - 1):
            if int(len(commands)) == 1:
                command_set: set = commands[0]
            else:
                command_set: set = commands[selection]
            if isinstance(command_set, tuple):
                function, *args = command_set
            else:
                function = command_set
                args = []
            result = function(*args)
            if result:
                break
        else:
            tries = invalidoption(tries, maxtries)


def testmenu(additional_title: str = ""):
    title: str = f"Test Menu {additional_title}"
    labels: list = ["Return to previous menu", "option1", "option2"]
    commands: list = [(returnselection,), (testmenu, "Option 1"), (print, "Option 2")]
    makemenu(title, labels, commands)


def mainmenu():
    title: str = "WGC Main Menu"
    labels: list = ["Quit WGC", "Configure shared networks", "Configure P2P networks", "Filebrowser", "Testmenu 1",
                    "Testmenu 2"]
    commands: list = [quitgracefully, (p2mpmenu,), (p2pmenu,), (filebrowser, Path.cwd()), (testmenu, "number 1"),
                      (testmenu, "number 2")]
    makemenu(title, labels, commands)


def filebrowser(path: Path):
    title: str = f"Filebrowser at {path}"
    labels: list = ["Back"]
    commands: list = [(returnselection,)]
    for child in path.iterdir():
        if child.is_file():
            labels.append(f"View File Contents of {child}")
            commands.append((view_file_content, child))
        elif child.is_dir():
            labels.append(f"View Directory {child}")
            commands.append((filebrowser, child))
    makemenu(title, labels, commands)


def view_file_content(file):
    if not file.is_file():
        print(f"Error, {file} is not a File")
    print()
    print(f"Content of {file}:")
    print(file.read_text())
    print("EOF")
    input("Press any Key to continue")


def p2mpmenu():
    filefilter: str = "-p2mp.conf"
    interfaces: list = listfile(wireguardpath, filefilter)
    title: str = "Shared Networks (P2MP Server)"
    labels: list = ["Return to Main Menu"]
    commands: list = [returnselection]
    for interface in interfaces:
        labels.append(interface)
        commands.append((modifyp2mpmenu, interface))
    labels.append("Set up a new shared network as the server")
    commands.append(createp2mp)
    makemenu(title, labels, commands)


def p2pmenu():
    print('p2p not yet done')


def returnselection():
    return True


def createp2mp():
    print("TBD")


def modifyp2mpmenu(interface: str):
    title: str = "Edit P2MP: " + interface
    labels: list = ["Return to P2MP selection", "Edit clients", "De-/activate network", "Parse Config (Test)"]
    commands: list = [returnselection, (modifyp2mpclientsmenu, interface), (p2mpupdownmenu, interface),
                      (readconfig, interface)]
    makemenu(title, labels, commands, )


def readconfig(filepath):
    file = open(wireguardpath / filepath, "r")
    config = file.readlines()
    file.close()
    linecount: int = 0
    intstartline: int = -1
    intendline: int = -1
    peerstartlines: list = []
    for line in config:
        line = line.strip()
        if line.find("[Interface]") == 0:
            intstartline = linecount
        if line.find("[Peer]") == 0:
            peerstartlines.append(linecount)
        linecount = linecount + 1
    if intstartline == -1:
        print("No valid interface config has been found in " + filepath)
    else:
        print("Interface config begins at line " + str(intstartline))
        interfaceConfig = ConfigInterface(filepath)
        peerstartlines.append(linecount)
        intendline = peerstartlines[0]

        for line in config[intstartline:intendline]:
            line = line.strip()
            if line.startswith("# Alias") or line.startswith("#Alias"):
                alias = line.split("=")[1].strip()
                interfaceConfig.Alias = alias
            elif line.startswith("Address"):
                ipv4: str = line.split("=")[1].split("/")[0].strip()
                ipv6: str = line.split("=")[1].split(",")[1].strip().split("/")[0].strip()
                interfaceConfig.ipv4 = ipv4
                interfaceConfig.ipv6 = ipv6
            elif line.startswith("ListenPort"):
                port: int = int(line.split('=')[1].strip())
            elif line.startswith("PrivateKey"):
                key: str = line.split("=")[1].strip()
                interfaceConfig.privkey = key
            else:
                continue

        for i in range(len(peerstartlines) - 1):
            peerstart: int = peerstartlines[i]
            peerend: int = peerstartlines[i + 1]
            peerConfig = ConfigPeer(filepath)

            for line in config[peerstart:peerend]:
                line = line.strip()
                if line.startswith("# Alias") or line.startswith("#Alias"):
                    alias = line.split("=")[1].strip()
                    peerConfig.alias = alias
                elif line.startswith("AllowedIPs"):
                    ipv4: str = line.split("=")[1].split("/")[0].strip()
                    ipv6: str = line.split("=")[1].split(",")[1].strip().split("/")[0].strip()
                    peerConfig.ipv4 = ipv4
                    peerConfig.ipv6 = ipv6
                elif line.startswith("PublicKey"):
                    key: str = line.split("=")[1].strip()
                    peerConfig.pubkey = key
                else:
                    peerConfig.alias = "Unnamed Peer"

            interfaceConfig.addpeer(peerConfig)
            print("Added Peer Config: ")
            peerConfig.printpeer()
            del peerConfig



def modifyp2mpclientsmenu(interface: str):
    interfacename: str = interface.split(".")[0].strip()
    title: str = "TBD Edit Clients on " + interfacename
    labels: list = ["Return to the previous menu"]
    commands: list = [returnselection]


def p2mpupdownmenu(interface: str):
    print("TBD")


def invalidoption(tries: int, maxtries: int):
    tries = tries + 1
    print("That is not a valid option. (" + str(tries) + "/" + str(maxtries) + ")")
    return tries


def quitgracefully():
    print("Thank you for using Wireguard Configurator!")
    quit(0)


class ConfigInterface:
    def __init__(self, interface: str, alias: str = "", ipv4: str = "", ipv6: str = "", port: int = "",
                 privkey: str = ""):
        self.interface = interface.split(".")[0].strip()
        self.alias: str = alias
        self.ipv4: str = ipv4
        self.ipv6: str = ipv6
        self.port: int = port
        self.privkey: str = privkey
        self.peers: list = []

    def addpeer(self, peer):
        self.peers.append(peer)

    def listpeers(self):
        print("Peers in " + self.interface)
        for peer in self.peers:
            peer.printpeer()


class ConfigPeer:
    def __init__(self, interface: str, alias: str = "", publickey: str = "", ipv4: str = "", ipv6: str = ""):
        self.interface = interface.split(".")[0].strip()
        self.alias: str = alias
        self.publickey: str = publickey
        self.ipv4: str = ipv4
        self.ipv6: str = ipv6

    def printpeer(self):
        print("Peer: " + self.alias)
        print("IPv4: " + self.ipv4)


wgc()
