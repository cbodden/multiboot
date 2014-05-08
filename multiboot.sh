#!/bin/bash
# vim:set ts=2 sw=4 noexpandtab:
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
#      REVISION: 14
#===============================================================================

LANG=C
set -e
set -o pipefail
set -o nounset
set -o errexit
NAME=$(basename $0)

# text format && color for messages
ORN=$(tput setaf 3); RED=$(tput setaf 1); BLU=$(tput setaf 4)
GRN=$(tput setaf 40); CLR=$(tput sgr0)
FMT="%s%-44s%s"
MNHDR="${BLU}[*]${CLR} "; BDHDR="${RED}[*]${CLR}"; COLHDR="${GRN}[*]${CLR} "
# printf "${FMT}" "${MNHDR}" "message" ": "

# OS check && trap statement
[[ $(uname) != "Linux" ]] && { printf "\nNeeds Linux\n"; exit 1; }
trap 'echo "${NAME}: Ouch! Quitting." 1>&2 ; exit 1' 1 2 3 9 15

# check for sudo / root
readonly R_UID="0"
[[ "${UID}" -ne "${R_UID}" ]] && { printf "\nNeeds sudo\n"; exit 1; }

readonly USBTMPDIR="/usbtmpdir"
readonly GRUBCONF="${USBTMPDIR}/boot/grub/grub.cfg"

function disk_detect()
{
  typeset -r MAINPROMPT="Select a disk to use: "
  declare -a ARR=(`for DRIVE in $(fdisk -l | grep Disk |
    grep -v "Disklabel\|identifier" | awk '{print $2}' | cut -d: -f1);
    do echo $DRIVE ; done`)
  PS3=$MAINPROMPT
  clear
  select DRV in "${ARR[@]}"; do
    case "${DRV}" in
      ${DRV}) [[ -n $(df | grep "${DRV}") ]] &&
        { echo -e "${DRV} is used by:\n$(df | grep "${DRV}")"; exit 1; } ||
        { readonly USBSTICK="${DRV}"; } ;;
    esac
    readonly DRV_CLEAN=$(echo "${USBSTICK}" | cut -d"/" -f3)
    break
  done
}

function disk_action()
{
  ## do not touch this section or you break the fdisk function!!!
  dd if=/dev/zero of=${USBSTICK} bs=1M count=1
fdisk ${USBSTICK} <<EOF
n
p
1


t
c
a
w
EOF
  mkfs.vfat ${USBSTICK}1
}

function grub_disk()
{
  mkdir ${USBTMPDIR}
  mount ${USBSTICK}1 ${USBTMPDIR}
  readonly UUID=$(ls -al /dev/disk/by-uuid/ | \
    grep ${DRV_CLEAN}1 | awk '{print $9}')
  [[ -n $(which grub2-install 2>/dev/null) ]] &&
    { grub2-install --no-floppy --root-directory=${USBTMPDIR} ${USBSTICK}; } ||
    { grub-install --no-floppy --root-directory=${USBTMPDIR} ${USBSTICK}; }
  mkdir ${USBTMPDIR}/iso/
}

function grub_header()
{
echo "set timeout=300
set default=0
set menu_color_normal=white/black
set menu_color_highlight=white/green
" >> ${GRUBCONF}
}

function cleanup()
{
  sync
  umount ${USBSTICK}1
  rm ${USBTMPDIR} -rf
}

function install_debian()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    local DL_ADDY="cdimage.debian.org/debian-cd/${VER}/${1}/iso-cd/"
    local IMAGE="debian-${VER}-${1}-netinst.iso"

echo "menuentry \"Debian netinst ${VER} ${1}\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"vga=normal --\"
  loopback loop \$isofile
  linux (loop)/install.amd/vmlinuz \$bo1
  initrd (loop)/install.amd/initrd.gz
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_fedora()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    [[ "$1" == i386 ]] && { local VER_3="i386"; local VER_6="i686"; } ||
      { local VER_3=$(echo ${1}); local VER_6=$(echo ${1}); }
    local DL_ADDY="mirror.pnl.gov/fedora/linux/releases/${VER}/Live/${VER_3}/"
    local IMAGE="Fedora-Live-Desktop-${VER_6}-${VER}-1.iso"
    local FED_OPTS="--class fedora --class gnu-linux --class gnu --class os"

echo "menuentry \"Fedora desktop ${VER} ${VER_3}\" ${FED_OPTS} {
  insmod loopback
  set isolabel=Fedora-Live-Desktop-${VER_6}-${VER}-1
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"iso-scan/filename=\$isofile\"
  set bo2=\"root=live:LABEL=\$isolabel ro rd.live.image quiet rhgb\"
  loopback loop (hd0,1)/\$isofile
  set root=(loop)
  linux /isolinux/vmlinuz0 \$bo1 \$bo2
  initrd /isolinux/initrd0.img
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_gentoo()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    local F_NAME="latest-install-${1}-minimal.txt"
    local SERVER="http://mirror.mcs.anl.gov/pub/gentoo/releases"
    local VER_L=$(curl -f -s ${SERVER}/${1}/autobuilds/${F_NAME} \
      | tail -n 1 | cut -d"/" -f1 )
    local DL_ADDY="${SERVER}/${1}/autobuilds/${VER_L}/"
    local IMAGE="install-${1}-minimal-${VER_L}.iso"

echo "menuentry \"Gentoo minimal ${VER_L} ${1}\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"root=/dev/ram0 init=/linuxrc nokeymap cdroot cdboot\"
  set bo2=\"looptype=squashfs loop=/image.squashfs initrd=gentoo.igz\"
  set bo3=\"usbcore.autosuspend=1 console=tty0 rootdelay=10 isoboot=\$isofile\"
  loopback loop \$isofile
  linux (loop)/isolinux/gentoo \$bo1 \$bo2 \$bo3
  initrd (loop)/isolinux/gentoo.igz
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_kali()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    local DL_ADDY="http://cdimage.kali.org/kali-latest/${1}/"
    local IMAGE="kali-linux-${VER}-${1}.iso"

echo "menuentry \"Kali Linux ${VER} ${1}\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"findiso=\$isofile boot=live noconfig=sudo username=root\"
  set bo2=\"hostname=kali quiet splash\"
  search --set -f \$isofile
  loopback loop \$isofile
  linux (loop)/live/vmlinuz \$bo1 \$bo2
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_netbsd()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    local DL_ADDY="mirror.planetunix.net/pub/NetBSD/NetBSD-${VER}/${1}/"
    local KNL_DL="binary/kernel/netbsd-INSTALL.gz"
    local KNL="netbsd-INSTALL.gz"
    local ST="binary/sets/"
    local WGET_OPT="-r -l 1 -nd -e robots=off -R '*.html*,*.gif'"
    local WGET_PATH="--directory-prefix=${USBTMPDIR}/iso/netbsd/${VER}/${1}/"

echo "menuentry \"NetBSD ${VER} ${1}\" {
  insmod ext2
  set root=(hd0,msdos1)
  knetbsd /iso/netbsd/${VER}/${1}/${KNL}
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${ST} ${WGET_OPT} ${WGET_PATH} || echo "NetBSD dloaded"
    wget ${DL_ADDY}${KNL_DL} ${WGET_PATH} || echo "NetBSD kernel dloaded"
    shift 1
  done
}

function install_openbsd()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    local DL_ADDY="openbsd.mirrors.hoobly.com/${VER}/${1}/"
    local WGET_OPT="-r -l 1 -nd -e robots=off -R '*.html*,*.gif'"
    local WGET_PATH="--directory-prefix=${USBTMPDIR}/${VER}/${1}/"

echo "menuentry \"OpenBSD ${VER} ${1}\" {
  insmod ext2
  set root=(hd0,msdos1)
  kopenbsd /${VER}/${1}/bsd.rd
}
" >> ${GRUBCONF}
    wget ${DL_ADDY} ${WGET_OPT} ${WGET_PATH} || echo "OpenBSD dloaded"
    shift 1
  done
}

function install_tails()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    local DL_ADDY="http://dl.amnesia.boum.org/tails/stable/tails-${1}-${VER}/"
    local IMAGE="tails-${1}-${VER}.iso"

echo "menuentry \"Tails ${VER} ${1} default\" {
  set isofile=\"/iso/${IMAGE}\"
  set isouuid=\"/dev/disk/by-uuid/${UUID}/iso/${IMAGE}\"
  set bo1=\"boot=live config\"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz fromiso=\$isouuid \$bo1
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}

echo "menuentry \"Tails ${VER} ${1} masquerade\" {
  set isofile=\"/iso/${IMAGE}\"
  set isouuid=\"/dev/disk/by-uuid/${UUID}/iso/${IMAGE}\"
  set bo1=\"boot=live config live-media=removable nopersistent noprompt quiet\"
  set bo2=\"timezone=Etc/UTC block.events_dfl_poll_msecs=1000 splash\"
  set bo3=\"nox11autologin module=Tails truecrypt quiet\"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz fromiso=\$isouuid \$bo1 \$bo2 \$bo3
  initrd (loop)/live/initrd.img
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_ubuntus()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    if [[ "${VER}" != "12.04.4" ]]; then
      [[ "$1" == i386 ]] && local EFI="" || local EFI=".efi"
    else
      local EFI=""
    fi
    local DL_ADDY="http://releases.ubuntu.com/${VER}/"
    local IMAGE="ubuntu-${VER}-server-${1}.iso"

echo "menuentry \"Ubuntu ${VER} server ${1}\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"cdrom-detect/try-usb=true file=/cdrom/preseed/ubuntu-server.seed\"
  set bo2=\"iso-scan/filename=\$isofile noprompt noeject --\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/install/vmlinuz${EFI} \$bo1 \$bo2
  initrd (loop)/install/initrd.gz
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

function install_ubuntud()
{
  local VER=$1
  shift 1
  while [[ $# -gt 0 ]]; do
    [[ "$1" == i386 ]] && EFI="" || EFI=".efi"
    local DL_ADDY="http://releases.ubuntu.com/${VER}/"
    local IMAGE="ubuntu-${VER}-desktop-${1}.iso"

echo "menuentry \"Ubuntu ${VER} desktop ${1}\" {
  set isofile=\"/iso/${IMAGE}\"
  set bo1=\"boot=casper iso-scan/filename=\$isofile noprompt noeject\"
  loopback loop (hd0,1)\$isofile
  linux (loop)/casper/vmlinuz${EFI} \$bo1
  initrd (loop)/casper/initrd.lz
}
" >> ${GRUBCONF}
    wget ${DL_ADDY}${IMAGE} --directory-prefix=${USBTMPDIR}/iso/
    shift 1
  done
}

#### functions to run below this line ####

disk_detect
disk_action
grub_disk
grub_header
install_debian 7.5.0 amd64 i386
install_fedora 20 x86_64 i386
install_gentoo current amd64 x86
install_kali 1.0.6 amd64
install_netbsd 6.1.3 amd64 i386
install_openbsd 5.5 amd64 i386
install_tails 1.0 i386
install_ubuntus 12.04.4 amd64 i386
install_ubuntud 13.10 amd64 i386
cleanup
