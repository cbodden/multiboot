#!/bin/bash
#===============================================================================
#
#          FILE: multiboot.sh
#
#         USAGE: sudo ./multiboot.sh
#
#   DESCRIPTION: This script creates a multiboot usb disk with multiple os's.
#
#       OPTIONS: none yet
#  REQUIREMENTS: grub2, wget, linux, dosfstools
#          BUGS: probably a bunch, have not discovered yet.
#         NOTES: Tested on gentoo with gentoo's version of grub2.
#                If your distro automounts usb, this script will fail.
#        AUTHOR: cesar@pissedoffadmins.com
#  ORGANIZATION: pissedoffadmins.com
#       CREATED: 15 April 2014
#      REVISION: 26
#===============================================================================

source core/selection.shlib
source core/main.shlib

if [ $# -ge 1 ]; then
  case "$1" in
    'debug'|'-d')
      selection
      grub_disk_debug
      grub_header
      for CMD in "${fnc_arr[@]}"; do $(echo ${CMD}) ; done
      cleanup_debug
    ;;

    'install'|'-i')
      selection
      disk_detect
      disk_action
      grub_disk
      grub_header
      for CMD in "${fnc_arr[@]}"; do $(echo ${CMD}) ; done
      cleanup
    ;;
  esac
else
  version
  description
  usage
  exit 1
fi
