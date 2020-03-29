# Wireguard Configurator Python edition
# This should be your one-stop shop to get Wireguard installed and configured

import os


operatingsystem: str = "Windows"
distribution: str = 'unknown'
wireguardpath: str = "./wireguard-test/wireguard"
selectedinterface: str = "wg0"


# Main Loop
def wgc():
    wgpath()
    clear()
    printlogo()
    mainmenu()


def wgpath():
    global wireguardpath
    os.chdir(wireguardpath)


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
    import os
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


def interfacesharedlist():
    wgpath()
    tries: int = 0
    i: int = 0
    maxtries: int = 3
    interfaces: list = listfile(os.getcwd(), '-s.conf')
    while tries < maxtries:
        print("There are currently " + str(len(interfaces)) + " interfaces with shared networks configured.")
        print("")
        print("0: Return to previous menu")
        for i in range(len(interfaces)):
            print(str(i + 1) + ": " + str(interfaces[i]))
        print(str(i + 2) + ": Set up a new shared interface")
        print("")
        selection: int = int(input("Please select an option [0-" + str(i + 2) + "]:"))
        print("Selection: " + str(selection))
        if selection == 0:
            print("Returning to previous menu")
            break
        elif 0 < selection < i + 2:
            print("Editing interface " + str(interfaces[selection - 1]))
        elif selection == i + 2:
            print("Create new shared interface")
        else:
            tries = invalidoption(tries, maxtries)


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
        if 0 <= selection <= int(len(labels)-1):
            if int(len(commands)) == 1:
                command: str = commands[0]
            else:
                command: str = commands[selection]
            if command == "break":
                break
            elif str(command).endswith(")"):
                exec(command)
            else:
                tries = 0
                command()
        else:
            tries = invalidoption(tries, maxtries)


def testmenu():
    title: str = "Test Menu"
    labels: list = ["Return to previous menu", "option1", "option2"]
    commands: list = ["break", testmenu, testmenu]
    makemenu(title, labels, commands)


def mainmenu():
    title: str = "WGC Main Menu"
    labels: list = ["Quit WGC", "Configure shared networks", "Configure P2P networks", "Testmenu"]
    commands: list = [quitgracefully, p2mpmenu, p2pmenu, testmenu]
    makemenu(title, labels, commands)


def p2mpmenu():
    filefilter: str = "-p2mp.conf"
    interfaces: list = listfile(os.getcwd(), filefilter)
    title: str = "Shared Networks (P2MP Server)"
    labels: list = ["Return to Main Menu"]
    labels.extend(interfaces)
    labels.append("Set up a new shared network as the server")
    commands: list = ["break"]
    commands.extend(["modifyp2mpmenu(selection, labels)"] * int(len(interfaces)))
    commands.append(createp2mp)
    makemenu(title, labels, commands)


def p2pmenu():
    print('p2p not yet done')


def returnselection():
    print("TBD")


def createp2mp():
    print("TBD")


def modifyp2mpmenu(selection: int, sel: list):
    config: str = sel[selection]
    title: str = "Edit P2MP: " + config
    labels: list = ["Return to P2MP selection", "Edit clients", "De-/activate network", "Parse Config (Test)"]
    commands: list = ["break", modifyp2mpclientsmenu, p2mpupdownmenu, readconfig(config)]
    makemenu(title, labels, commands)


def readconfig(filepath: str):
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
        print("No valid interface config has been found in " + filepath)
    else:
        print("Interface config begins at line " + str(intstartline))
        if int(len(peerstartlines)) > 0:
            print("Found " + str(len(peerstartlines)) + " peer configs at lines: ")
            for i in peerstartlines:
                print(i)
        else:
            print("Found no peers configured in " + filepath)


def modifyp2mpclientsmenu():
    print("TBD")


def p2mpupdownmenu():
    print("TBD")


def invalidoption(tries: int, maxtries: int):
    tries = tries + 1
    print("That is not a valid option. ("+ str(tries) + "/" + str(maxtries) + ")")
    return tries


def quitgracefully():
    print("Thank you for using Wireguard Configurator!")
    quit(0)


class ConfigInterface:
    interfaceipv4: str = ""
    interfaceipv6: str = ""
    listenport: int = ""
    privatekey: str = ""


class ConfigPeer:
    peername: str = ""
    publickey: str = ""
    peeripv4: str = ""
    peeripv6: str = ""


wgc()
