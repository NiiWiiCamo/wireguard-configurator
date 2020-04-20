# Wireguard Configurator Python edition
# This should be your one-stop shop to get Wireguard installed and configured

import os
from pathlib import Path
from typing import List

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


# Getting your menu displayed. Might be useful for visualizing lists.
# Like Menu items. Or lists.
def printlistmenu(lis: list):
    for i in range(len(lis)):
        print(str(i) + ": " + str(lis[i]))


# The girl from next door
class MenuItemAlice(object):
    label: str = None
    label_is_static: bool = True
    label_arguments: dict = {}
    action: list = []

    def __init__(self):
        pass  # Do nothing

    def set_static_label(self, value):
        self.label_is_static = True
        self.label_arguments = {}
        self.label = value
        return self

    def set_dynamic_lable(self, format_string, **kwargs):
        self.label_is_static = False
        self.label_arguments = kwargs
        self.label = format_string
        return self

    def set_action(self, *args):
        self.action = args
        return self

    def get_label(self):
        if self.label_is_static:
            return self.label
        else:
            return self.label.format(**self.label_arguments)
        
    def run_action(self):
        if isinstance(self.action, tuple):
            function, *args = self.action
        else:
            function = self.action
            args = []
        return function(*args)


# Your friendly neighbourhood menu builder. Might be called Bob.
class MenuBob(object):

    def __init__(self, titel: str, maxtries: int =3):
        self.titel = titel
        self.maxtries = maxtries
        self.menu_items: List[MenuItemAlice] = []
        self.description = None

    def addItem(self, item):
        self.menu_items.append(item)

    def print_menu(self):
        print()
        print(self.titel)
        self.print_description()
        for item in self.menu_items:
            label = item.get_label()
            label_num = self.menu_items.index(item)
            print(f"{label_num}: {label}")
    
    def set_description(self,description):
        self.description=description
    
    def print_description(self):
        if self.description is not None:
            print(self.description)
            
    def run(self):
        tries: int = 0
        while tries < self.maxtries:
            self.print_menu()
            selection: int = int(input(f"Please select an option [0-{str(len(self.menu_items) - 1)}]:"))
            if 0 <= selection <= int(len(self.menu_items) - 1):
                item=self.menu_items[selection]
                result = item.run_action()
                
                if result:
                    break




# Bob's mom, always encouraging and ready to help.
def testmenu(additional_title: str = ""):
    menu=MenuBob(f"Test Menu {additional_title}")
    
    item=MenuItemAlice()
    item.set_static_label("Return to previous menu")
    item.set_action(returnmenu)
    menu.addItem(item)
        
    item=MenuItemAlice()
    item.set_static_label("option1")
    item.set_action(testmenu, "Option 1")
    menu.addItem(item)
        
    item=MenuItemAlice()
    item.set_static_label("option2")
    item.set_action(testmenu, "Option 2")
    menu.addItem(item)
    
    menu.run()


# The. Menu.
def mainmenu():
    menu=MenuBob(titel="WGC Main Menu")
    
    item=MenuItemAlice()
    item.set_static_label("Quit WGC")
    item.set_action(quitgracefully)
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Configure shared networks")
    item.set_action(p2mpmenu)
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("filebrowser")
    item.set_action(filebrowser,Path("."))
    menu.addItem(item)
    
    menu.run()


# Something @jkoan did to teach me, don't know why I keep it.
def filebrowser(path: Path):
    menu=MenuBob(f"Filebrowser at {path}")
    item=MenuItemAlice()
    item.set_static_label("Back")
    item.set_action(returnmenu)
    menu.addItem(item)
    for child in path.iterdir():
        item=MenuItemAlice()
        if child.is_file():
            item.set_static_label(f"View File Contents of {child}")
            item.set_action(view_file_content, child)
        elif child.is_dir():
            item.set_static_label(f"View Directory {child}")
            item.set_action(filebrowser, child)
        menu.addItem(item)
    menu.run()


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
    menu=MenuBob("Shared Networks (P2MP Server)")
    item=MenuItemAlice()
    item.set_static_label("Return to Main Menu")
    item.set_action(returnmenu)
    menu.addItem(item)
    for interface in interfaces:
        item=MenuItemAlice()
        item.set_static_label(interface)
        item.set_action(modifyp2mpmenu, interface)
        menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Set up a new shared network as the server")
    item.set_action(createp2mp)
    menu.addItem(item)
    menu.run()


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

    menu=MenuBob(f"Editing: {intname}")

    item=MenuItemAlice()
    item.set_static_label("Return to P2MP selection")
    item.set_action(returnmenu)
    menu.addItem(item)
        
    item=MenuItemAlice()
    item.set_static_label("Print Peers")
    item.set_action(conf.listpeers)
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Edit clients")
    item.set_action(p2mppeerselectmenu, conf)
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Add client")
    item.set_action(p2mpaddpeer, conf)
    menu.addItem(item)
        
    item=MenuItemAlice()
    item.set_static_label("De-/activate network")
    item.set_action(p2mpupdownmenu, interface)
    menu.addItem(item)    
    menu.run()

    if askyesno("Do you want to backup and save?"):
        if backup(filepath):
            os.remove(filepath)
            writeconfig(conf, filepath)

# The thing you might do after reading and before writing
def p2mppeerselectmenu(conf):
    intname = conf.interface
    alias = conf.alias
    menu=MenuBob(f"Editing P2MP Interface: {intname}")
    
    item=MenuItemAlice()
    item.set_static_label("Return to previous menu")
    item.set_action(returnmenu)
    menu.addItem(item)

    desc=""
    if alias != "":
        desc+=f"Interface Alias: {alias}\n"
    desc=f"Active peer configs:"
    
    menu.set_description(desc)
    for peer in conf.peers:
        item=MenuItemAlice()
        item.set_dynamic_lable("\nAlias: {peer.alias}\nIPv4 : {peer.ipv4}\nIPv6 : {peer.ipv6}\n",
                               peer=peer)
        item.set_action(p2mppeermenu, peer)
        menu.addItem(item)
    menu.run()

def p2mppeermenu(peer):
    peer.printpeer()
    menu=MenuBob("")
    
    item=MenuItemAlice()
    item.set_static_label("Return to previous menu")
    item.set_action(returnmenu)
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Edit Alias")
    item.set_action(peeredit, peer, "alias")
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Edit IPv4")
    item.set_action(peeredit, peer, "ipv4")
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Edit IPv6")
    item.set_action(peeredit, peer, "ipv6")
    menu.addItem(item)
    
    item=MenuItemAlice()
    item.set_static_label("Edit Public Key")
    item.set_action(peeredit, peer, "publickey")
    menu.addItem(item)
    
    menu.run()
    

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


# The actual config file parser.
# Puts everything away neatly into an object and returns that to you.
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
