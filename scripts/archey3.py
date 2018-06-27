#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This script will setup archey3 for
# the user that is running this script

import os

config_file = """[core]
color = {}
align = center
display_modules = de(), distro(), uname(r), fs(/), ram(), uname(n), packages(), uptime()
"""

run_cmd = """

# Output system info using archey3 (https://lclarkmichalek.github.io/archey3/)
[ -r /usr/bin/archey3 ] && clear && /usr/bin/archey3
"""

# Add archey3 execute command to user shell config
usershell = os.environ["SHELL"]
if usershell == "/bin/zsh":
    shell_config_path = os.path.expanduser("~/.zshrc")
elif usershell == "/bin/bash":
    shell_config_path = os.path.expanduser("~/.bashrc")
else:
    print("User shell '{}' is not supported".format(usershell))
    exit(1)

# Gracefully fail if the user shell config file is missing
if not os.path.exists(shell_config_path):
    print("User shell file '{}' is missing. Aborting".format(shell_config_path))
    exit(1)

# Install archey3 if missing
os.system("sudo pacman -Sy --noconfirm --needed archey3")

# Make sure that config directory exists
config_path = os.path.expanduser("~/.config/")
if not os.path.exists(config_path):
    print("Creating missing 'config' directory")
    os.mkdir(config_path)

# Create archey3 config file
filepath = os.path.join(config_path, "archey3.cfg")
with open(filepath, "w") as stream:
    # Change output color to red if current user is the root user
    # Esle set color to cyan for all other users
    if os.geteuid() == 0:
        data = config_file.format("red")
    else:
        data = config_file.format("cyan")

    if os.path.exists(filepath):
        print("Updating archey3 config: {}".format(filepath))
    else:
        print("Creating archey3 config: {}".format(filepath))

    stream.write(data)

# Make sure that the archey3 run command don't
# already exist within the shell config file
with open(shell_config_path, "r") as stream:
    if "/usr/bin/archey3" in stream.read():
        print("Archey3 shell command already exists")
        exit(0)

# Add archey3 run command to shell config
with open(shell_config_path, "a") as stream:
    print("Adding Archey3 shell command to: {}".format(shell_config_path))
    stream.write(run_cmd)
