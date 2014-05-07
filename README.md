multiboot
=========

This script is used to create a grub2 bootable flash disc with multiple
linux distros and OpenBSD.

As of writing, these are the OS'es that are being installed:
- debian 7.4.0 netinstall (amd64 & i386)
- fedora 20 live (x86-64 & i386)
- gentoo current minimal (amd64 & x86)
- kali 1.0.6 live (amd64)
- netbsd 6.1.3 (amd64 & i386)
- openbsd 5.5 (amd64 & i386)
- tails 1.0 live (i386)
- ubuntu server 12.04.4 (amd64 & i386)
- ubuntu desktop 13.10 (amd64 & i386)

Requirements
----

-  Linux       (tested on gentoo: http://www.gentoo.org/)
-  Bash        (http://tiswww.case.edu/php/chet/bash/bashtop.html)
-  Wget        (http://www.gnu.org/software/wget/)
-  Grub2       (https://www.gnu.org/software/grub/)
-  Dosfstools  (http://daniel-baumann.ch/software/dosfstools/)

Todo / Add
----
- lots of stuff....


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
