#!/bin/bash

# This script will build an archiso ready to be run on a Secure Boot enabled PC/laptop.

# It expects your certificate (DB.key, DB.crt) to be in the current directory.
# If you want to be able to enroll your certificate, also include DB.cer, so that the script finds it
# and add it to the ESP of the generated ISO

# It will create
# - a directory /tmp/customXXXXXX.d to build package and host a custom repo
# - a working directory workXXXXX in the current directory
# - a directory for mkarchiso /tmp/outXXXXXX.d
# and output the resulting iso in the current directory
# and then clean-up those tmp dirs

# DEPENDS ON: sudo, findmnt [util-linux], sbsign [sbsigntools], mkarchiso [archiso] (obviously)

usage() {
	echo "Usage: $0 [-h|-v]"
	echo "     -h  Display this help"
	echo "     -v  Verbose output when building the iso (output of mkarchiso)"
}

if [[ "$1" == "-h" ]] ;then
	usage
	exit 0
fi

verbose="false"
if [[ "$1" == "-v" ]] ;then
	verbose="true"
else
	echo "Note: use the '-v' flag to get output of mkarchiso"
fi

if ! command -v mkarchiso &> /dev/null; then
	echo "You need to install mkarchiso" >&2
	exit 1
fi
if ! command -v sbsign &> /dev/null; then
	echo "You need to install sbsigntools" >&2
	exit 1
fi

if [[ ! -f DB.crt ]] ;then
	echo "DB.crt not found" >&2
	exit 1
fi
if [[ ! -f DB.key ]] ;then
	echo "DB.key not found" >&2
	exit 1
fi

cwd=$PWD
customd=`mktemp -d /tmp/customXXXXXX.d`

build_package() {
	cd $customd
	pkg=$1.tar.gz
	echo ":: Downloading $1 from AUR"
	wget --quiet "https://aur.archlinux.org/cgit/aur.git/snapshot/$pkg"
	tar xzf $pkg
	echo ":: Building $1 package"
	cd $1
	BUILDDIR="." PKGDEST="." SRCDEST="." SRCPKGDEST="." makepkg
	mv $1-*.pkg.* ..
}
build_package shim-signed

cd $customd
echo ":: Creating custom local repo"
repo-add custom.db.tar.gz shim-signed-*.pkg.*

cd $cwd
echo ":: Creating custom archiso profile"
work=`mktemp -d $cwd/workXXXXXX`
echo "Using $work as work directory"

echo ":: Copying certificates"
cp DB.{key,crt,cer} $work 2>/dev/null

cd $work
cp -r /usr/share/archiso/configs/releng prof
echo "shim-signed" >> prof/packages.x86_64
echo "mokutil" >> prof/packages.x86_64

sed -i "$(( $(wc -l < prof/pacman.conf) - 3 + 1)),\$s/#//g" prof/pacman.conf
sed -i '$s|/home/custompkgs|'$customd'|' prof/pacman.conf

echo ":: Patching private mkarchiso version"
cp /usr/bin/mkarchiso .
patch -p0 -i $cwd/mkarchiso.patch

out=`mktemp -d /tmp/outXXXXXX.d`
echo "Using $out as output directory"
echo ":: Running mkarchiso (as root)"
if [[ "$verbose" == "true" ]] ;then
	sudo ./mkarchiso -v -o $cwd -w $out prof
else
	sudo ./mkarchiso -o $cwd -w $out prof
fi

echo ":: Cleaning up"
if ! findmnt|grep -q $out; then
	sudo rm -rf $out 2>/dev/null
else
	echo "There are left-over files in $out. Please be careful to unmount any mount before deleting the directory. See https://wiki.archlinux.org/index.php/Archiso#Removal_of_work_directory" >&2
fi
rm -rf $work
rm -rf $customd
