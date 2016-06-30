![Unsupported](https://img.shields.io/badge/development_status-in_progress-green.svg)


multiboot
=========
This script is used to create a grub2 bootable flash disc with multiple
current linux distros, OpenBSD, and NetBSD.
At present for full install, you will need a flash disk of at least 4GB
or larger.

These are the OS'es that are currently being supported:
- alpine extended (amd64 & i386)
- centos minimal (x86_64)
- debian netinstall (amd64 & i386)
- gentoo current minimal (amd64 & x86)
- grml
- kali live (amd64)
- netbsd (amd64 & i386)
- openbsd (amd64)
- tails live & masquerade (i386)
- ubuntu desktop (amd64 & i386)
- ubuntu server (amd64 & i386)

Requirements
----
-  Linux       (tested on gentoo: http://www.gentoo.org/)
-  Bash        (http://www.gnu.org/software/bash/)
-  Wget        (http://www.gnu.org/software/wget/)
-  cURL        (http://curl.haxx.se)
-  Grub2       (https://www.gnu.org/software/grub/)
-  Dosfstools  (http://daniel-baumann.ch/software/dosfstools/)
-  Parted      (http://www.gnu.org/software/parted)

Installation / Usage
----
```
git clone git@github.com:cbodden/multiboot.git
cd multiboot
sudo ./multiboot.sh
```

Todo / Add
----
- need to update documentation
- lots of other stuff....

Troubleshooting
----
This script was tested using a system that does not automount the usb
flash drive.
If your distro automounts the flash disk, try unmounting it first before
running this script.

License and Author
----
Author:: Cesar Bodden (cesar@pissedoffadmins.com)

Copyright:: 2014, Pissedoffadmins.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
