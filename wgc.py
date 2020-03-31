# Wireguard Configurator Python edition
# This should be your one-stop shop to get Wireguard installed and configured

import os
from pathlib import Path
import copy

operatingsystem: str = "Windows"
distribution: str = 'unknown'
wireguardpath: str = Path('.') / "wireguard-test" / "wireguard"
config_cache = {}

# Main Loop. Yes.
def wgc():
    clear()
    printlogo()
    mainmenu()


# Because MARKETING!
def printlogo():
    print("oooooo   oooooo     oooo   .oooooo.      .oooooo.      ")
    print(" `888.    `888.     .8'   d8P'  `Y8b    d8P'  `Y8b     ")
    print("  `888.   .8888.   .8'   888           888             ")
    print("   `888  .8'`888. .8'    888           888             ")
    print("    `888.8'  `888.8'     888     ooooo 888             ")
    print("     `888'    `888'      `88.    .88'  `88b    ooo     ")
    print("      `8'      `8'        `Y8bood8P'    `Y8bood8P'  .py")
    print("WireGuard Configurator - Python Edition")


# The things you do first are not always bad. This might be though.
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


# Does this even work?
def clear():
    if os.name == 'nt':
        os.system('cls')
    else:
        os.system('clear')


# Because you might want to know what files are actually there.
def listfile(path: str, filefilter: str):
    lis: list = []
    for file in os.listdir(path):
        if file.endswith(filefilter):
            lis.append(file)
    return lis


# Getting your menu displayed. Might be useful for visualizing lists. Like Menu items. Or lists.
def printlistmenu(lis: list):
    for i in range(len(lis)):
        print(str(i) + ": " + str(lis[i]))


# Your friendly neighbourhood menu builder. Might be called Bob.
def makemenu(title: str, labels: list, commands: list, maxtries: int = 3):
    tries: int = 0
    if int(len(labels)) != int(len(commands)):
        print("There are " + str(len(labels)) + " labels and " + str(len(commands)) + " commands passed in this menu.")
        print("You must pass the same number of commands .")
    while tries < maxtries:
        print("")
        if title != "":
            print(title)
        printlistmenu(labels)
        selection = input("Please select an option [0-" + str(len(labels) - 1) + "]:")
        if selection.isdigit():
            selection: int = int(selection)
        else:
            tries = invalidoption(tries, maxtries)
            continue
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
            if function == "returnselection":
                return selection
            else:
                result = function(*args)
            if result:
                break
        else:
            tries = invalidoption(tries, maxtries)


# Bob's mom, always encouraging and ready to help.
def testmenu(additional_title: str = ""):
    title: str = f"Test Menu {additional_title}"
    labels: list = ["Return to previous menu", "option1", "option2"]
    commands: list = [(returnmenu,), (testmenu, "Option 1"), (print, "Option 2")]
    makemenu(title, labels, commands)


# The. Menu.
def mainmenu():
    title: str = "WGC Main Menu"
    labels: list = ["Quit WGC", "Configure shared networks", "Configure P2P networks"]
    commands: list = [quitgracefully, p2mpmenu, p2pmenu]
    makemenu(title, labels, commands)


# Something @jkoan did to teach me, don't know why I keep it.
def filebrowser(path: Path):
    title: str = f"Filebrowser at {path}"
    labels: list = ["Back"]
    commands: list = [(returnmenu,)]
    for child in path.iterdir():
        if child.is_file():
            labels.append(f"View File Contents of {child}")
            commands.append((view_file_content, child))
        elif child.is_dir():
            labels.append(f"View Directory {child}")
            commands.append((filebrowser, child))
    makemenu(title, labels, commands)


# Another thing from @jkoan. Keeping this so filebrowser doesn't get lonely.
def view_file_content(file):
    if not file.is_file():
        print(f"Error, {file} is not a File")
    print()
    print(f"Content of {file}:")
    print(file.read_text())
    print("EOF")
    input("Press any Key to continue")


# Shared network menu. Basic beach.
def p2mpmenu():
    filefilter: str = "-p2mp.conf"
    interfaces: list = listfile(wireguardpath, filefilter)
    title: str = "Shared Networks (P2MP Server)"
    labels: list = ["Return to Main Menu"]
    commands: list = [returnmenu]
    for interface in interfaces:
        labels.append(interface)
        commands.append((modifyp2mpmenu, interface))
    labels.append("Set up a new shared network as the server")
    commands.append(createp2mp)
    makemenu(title, labels, commands)


# P2P network menu. Just as basic.
def p2pmenu():
    print('p2p not yet done')


# Basically readconfigs equally hot cousin. Does everything backwards.
def createp2mp():
    print("TBD")


# Something, something, I might need this later.
def modifyp2mpmenu(interface: str):
    filepath = wireguardpath / interface
    # ask cache if config is parsed otherwise parse a new one
    conf: ConfigInterface = config_cache.get(interface, None)
    if conf is None:
        conf: ConfigInterface = readconfig(filepath)
        config_cache[interface] = conf
    intname = conf.interface
    alias: str = conf.alias
    ipv4 = conf.ipv4
    ipv6 = conf.ipv6
    peercount: int = len(conf.peers)
    print("")
    print(f"Interface settings for {intname}:")
    if alias != "":
        print("Interface Alias: " + alias)
    print("IPv4 Address: " + ipv4)
    print("IPv6 Address: " + ipv6)
    print("No. of peers: " + str(peercount))
    title: str = ""
    labels: list = ["Return to P2MP selection", "Print Peers", "Edit clients", "Add client", "De-/activate network"]
    commands: list = [returnmenu, conf.listpeers, (p2mppeerselectmenu, conf), (p2mpaddpeer, conf),
                      (p2mpupdownmenu, interface)]
    makemenu(title, labels, commands)
    if askyesno("Do you want to backup and save?"):
        if backup(filepath):
            os.remove(filepath)
            writeconfig(conf, filepath)

# The thing you might do after reading and before writing
def p2mppeerselectmenu(conf):
    intname = conf.interface
    alias = conf.alias
    title: str = ""
    labels: list = ["Return to previous menu"]
    commands: list = [returnmenu]
    print("")
    print("Editing P2MP Interface: " + intname)
    if alias != "":
        print("Interface Alias: " + alias)
    print("")
    print("Active peer configs:")
    for peer in conf.peers:
        labels.append(f"\nAlias: {peer.alias}\nIPv4 : {peer.ipv4}\nIPv6 : {peer.ipv6}\n")
        commands.append((p2mppeermenu, peer))
    makemenu(title, labels, commands)
    return True  # Skip this menu until labels are dynamic

def p2mppeermenu(peer):
    peer.printpeer()
    title: str = ""
    labels: list = ["Return to previous menu", "Edit Alias", "Edit IPv4", "Edit IPV6", "Edit Public Key"]
    commands: list = [returnmenu, (peeredit, peer, "alias"), (peeredit, peer, "ipv4"),
                      (peeredit, peer, "ipv6"), (peeredit, peer, "publickey")]
    makemenu(title, labels, commands)
    

def peeredit(peer, option: str):
    attribute = getattr(peer, option)
    print("Current value for " + option + " : " + attribute)
    newvalue = input("Enter new value or 0 to cancel: ")  # TODO: better use empty string => Is it though?
    if newvalue != "0":
        setattr(peer, option, newvalue)


def p2mpaddpeer(conf):
    print("TBD")


# Turn me on! Flip my switch!
def p2mpupdownmenu(interface: str):
    print("TBD")


# The actual config file parser. Puts everything away neatly into an object and returns that to you.
def readconfig(filepath):
    file = open(filepath, "r")
    config = file.readlines()
    file.close()
    linecount: int = 0
    intstartline: int = -1
    peerstartlines: list = []
    for line in config:
        line = line.strip()
        if line.find("[Interface]") == 0:
            intstartline = linecount
        if line.find("[Peer]") == 0:
            peerstartlines.append(linecount)
        linecount = linecount + 1
    if intstartline == -1:
        raise Exception("No valid interface config has been found in " + str(filepath))
    interfaceConfig = ConfigInterface(filepath.stem)
    peerstartlines.append(linecount)
    intendline: int = peerstartlines[0]

    # Parse Interface block, add to instanced object
    for line in config[intstartline:intendline]:
        line = line.strip()
        if line.startswith("# Alias") or line.startswith("#Alias"):
            interfaceConfig.alias = line.split("=")[1].strip()
        elif line.startswith("Address"):  # Includes netmask
            interfaceConfig.ipv4 = line.split("=")[1].split(",")[0].strip()
            interfaceConfig.ipv6 = line.split("=")[1].split(",")[1].strip()
        elif line.startswith("ListenPort"):
            interfaceConfig.port = int(line.split('=')[1].strip())
        elif line.startswith("PrivateKey"):
            interfaceConfig.privkey = line.split("=")[1].strip()
        elif line.startswith("PreUp"):
            interfaceConfig.preup = line.split("=")[1].strip()
        elif line.startswith("PostUp"):
            interfaceConfig.postup = line.split("=")[1].strip()
        elif line.startswith("PreDown"):
            interfaceConfig.predown = line.split("=")[1].strip()
        elif line.startswith("PostDown"):
            interfaceConfig.postdown = line.split("=")[1].strip()

    # Parse Peer block, add to instanced object, add object to list in interface config, delete object
    for i in range(len(peerstartlines) - 1):
        peerstart: int = peerstartlines[i]
        peerend: int = peerstartlines[i + 1]
        peerConfig = ConfigPeer()

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
                peerConfig.publickey = line.split(" ")[2].strip()
            elif peerConfig.alias == "":
                peerConfig.alias = "Unnamed Peer"

        interfaceConfig.addpeer(peerConfig)
        del peerConfig

    # Returns interface config object
    return interfaceConfig


# The thing before The Magic Key (Track 5)
def backup(filepath):
    import shutil
    filebackuppath: str = ""
    if os.path.isfile(filepath):
        tmp1: Path = Path(str(filepath) + ".bck")
        if os.path.isfile(tmp1):
            for i in range(99):
                tmp2: Path = Path(str(tmp1) + str(i))
                if os.path.isfile(tmp2):
                    continue
                else:
                    filebackuppath = tmp2
                    break
            if filebackuppath == "":
                raise Exception("Too many backups already existing!")
        else:
            filebackuppath = tmp1
        shutil.copyfile(filepath, filebackuppath)
        return True
    else:
        raise Exception("File does not exist!")


# The Magic Key, needs config to NOT exist already. Backup / move beforehand!
def writeconfig(conf, filepath):
    if os.path.isfile(filepath):
        raise Exception("File already exists. Overwriting currently not supported!")
    f = open(filepath, "x")
    lines: list = ["# Config file generated by Wireguard Configurator (wgc.py)", "# at " + timestamp(), "[Interface]"]
    # If Alias exists write to config
    if conf.alias != "":
        lines.append("# Alias = " + conf.alias)

    # Build address line
    address: str = conf.ipv4
    if address != "":
        address = address + "/32"
    if conf.ipv6 != "":
        if address != "":
            address = address + ","
        address = address + conf.ipv6 + "/128"
    lines.append("Address = " + address)

    # Port line
    lines.append("ListenPort = " + str(conf.port))
    # Private Key
    lines.append("PrivateKey = " + conf.privkey)

    # PreUp
    if conf.preup != "":
        lines.append("PreUp = " + conf.preup)
    # PostDown
    if conf.postup != "":
        lines.append("PostUp = " + conf.postup)
    # PreDown
    if conf.predown != "":
        lines.append("PreDown = " + conf.predown)
    # PostDown
    if conf.postdown != "":
        lines.append("PostDown = " + conf.postdown)

    # Peer configs:
    for peer in conf.peers:
        lines.append("[Peer]")
        # If Alias exists write to config
        if not peer.alias == "" or peer.alias == "Unnamed Peer":
            lines.append("# Alias = " + peer.alias)

        # Build address line
        address: str = peer.ipv4
        if peer.ipv6 != "":
            if address != "":
                address = address + ","
            address = address + peer.ipv6
        lines.append("Address = " + address)
        # Public Key
        lines.append("PublicKey = " + peer.publickey)

    # Write lines to file and close
    for line in lines:
        f.write(line + "\n")
    f.close()


# Make timestamp. For stamping. Time.
def timestamp():
    import time
    t = time.localtime(time.time())
    stamp = "%d-%d-%d %d:%d:%d" % (
        t.tm_mday, t.tm_mon, t.tm_year, t.tm_hour, t.tm_min, t.tm_sec)
    return stamp


# For when the user entered something invalid in a menu. Might give them another chance.
def invalidoption(tries: int, maxtries: int):
    tries = tries + 1
    print("That is not a valid option. (" + str(tries) + "/" + str(maxtries) + ")")
    return tries


# Menu leaver. Basically "There's the door."
def returnmenu():
    return True


# Menu returner. I'll take door number three, Bob.
def returnselection(selection: int):
    return selection


# For when you don't throw a tantrum and want to thank the user.
def quitgracefully():
    print("Thank you for using Wireguard Configurator!")
    quit(0)


class ConfigInterface:
    def __init__(self, interface: str, alias: str = "", ipv4: str = "", ipv6: str = "", port: int = "",
                 privkey: str = "", preup: str = "", postup: str = "", predown: str = "", postdown: str = ""):
        self.interface = interface
        self.alias: str = alias
        self.ipv4: str = ipv4
        self.ipv6: str = ipv6
        self.port: int = port
        self.privkey: str = privkey
        self.preup: str = preup
        self.postup: str = postup
        self.predown: str = predown
        self.postdown: str = postdown
        self.peers: list = []

    def addpeer(self, peer):
        self.peers.append(peer)

    def listpeers(self):
        print("Peers in " + self.interface)
        for peer in self.peers:
            peer.printpeer()
            print()


class ConfigPeer:
    def __init__(self, alias: str = "", publickey: str = "", ipv4: str = "", ipv6: str = ""):
        self.alias: str = alias
        self.publickey: str = publickey
        self.ipv4: str = ipv4
        self.ipv6: str = ipv6

    def printpeer(self):
        print("Peer: " + self.alias)
        print("IPv4: " + self.ipv4)
        if self.ipv6 != "":
            print("IPv6: " + self.ipv6)
        else:
            print("IPv6 not configured")
        print("Public key: " + self.publickey)


wgc()
