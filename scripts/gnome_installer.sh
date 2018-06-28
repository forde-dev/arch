#!/usr/bin/env bash
set -e
set -u

pacman -S gnome

systemctl enable gdm.service

echo "This requires a reboot to take effect" 
