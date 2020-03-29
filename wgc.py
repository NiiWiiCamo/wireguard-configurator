# Wireguard Configurator Python edition
# This should be your one-stop shop to get Wireguard installed and configured


operatingsystem: str = "Windows"
distribution: str = 'unknown'
wgpath: str = "./wireguard-test/wireguard"
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
    import os
    if os.name == 'nt':
        os.system('cls')
    else:
        os.system('clear')


def listfile(path: str, filefilter: str):
    import os
    lis: list = []
    for file in os.listdir(path):
        if file.endswith(filefilter):
            lis.append(file)
    return lis


def interfacesharedlist():
    global wgpath
    tries: int = 0
    i: int = 0
    maxtries: int = 3
    interfaces = listfile(wgpath, '-s.conf')
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
        print("These numbers must match. Please check the menu configuration.")
    while tries < maxtries:
        print("")
        print(title)
        printlistmenu(labels)
        selection: int = int(input("Please select an option [0-" + str(len(labels) -1) + "]:"))
        if 0 <= selection <= int(len(labels)-1) and selection <= int(len(commands)-1):
            command = commands[selection]
            if command == "break":
                break
            else:
                tries = 0
                exec(command)
        else:
            tries = invalidoption(tries, maxtries)


def testmenu():
    title: str = "Test Menu"
    labels: list = ["Return to previous menu", "option1", "option2"]
    commands: list = ["break", "print('Option 1')", "print('Option 2')"]
    makemenu(title, labels, commands)


def mainmenu():
    title: str = "WGC Main Menu"
    labels: list = ["Quit WGC", "Configure shared networks", "Configure P2P networks", "Testmenu"]
    commands: list = ["quitgracefully()", "interfacesharedlist()", "print('p2p not yet done')", "testmenu()"]
    makemenu(title, labels, commands)


def invalidoption(tries: int, maxtries: int):
    tries = tries + 1
    print("That is not a valid option. ("+ str(tries) + "/" + str(maxtries) + ")")
    return tries


def quitgracefully():
    print("Thank you for using Wireguard Configurator!")
    quit(0)


wgc()
