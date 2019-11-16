# WireGuardConfigurator - making my life easier

Starting out as a little script to make deploying wireguard on a Raspberry easier, grew to a collection of scripts.
Currently indev, as soon as basic functionality is reached will be pushed to master to replace the old scripts.
Because of the nature of the scripts, everything needs to be run as root (sudo). As always, check any scripts yourself before executing them!

I am developing these scripts currently for Raspbian/Debian 10 (Buster). Might implement support for others later, although unlikely.

Thanks @jkoan for the constant support and help!
If you find any mistakes/bad scripting, tell me where and what. I am a Bash n00b just trying to make life a little bit easier for people like me.


Current status:

wgc-config		Contains all the parameters
wgc-installer		Installs wireguard and sets up your system
wgc-generator		Generates Client configs including keys and adds them to the server config.
wgc-uninstaller		Undoes everything wgc-installer does. Asks for export, calls wgc-exporter.
wgc-exporter		Exports your created config files to a tarball and optionally as filetree.

wgc-ungenerator	(TBD)	Undoes everything wgc-generator does and removes specific client configs.
wgc-importer	(TBD)	Imports existing configs, will be called by wgc-installer.
wgc-master	(TBD)	Master of puppets, master suite to call all other scripts. For convenience only.
