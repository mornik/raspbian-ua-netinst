#!/bin/bash
export DEBUG=1
export LOG=$(pwd)/log
>$LOG
debug(){
if [ $DEBUG -eq 0 ]; then
    echo "DEBUG : line $LINENO : $1"|tee -a $LOG
fi
}

mirror=http://archive.raspbian.org/raspbian/
release=jessie
packages="busybox-static libc6 cdebootstrap-static e2fslibs e2fsprogs libcomerr2 libblkid1 libuuid1 libgcc1 dosfstools linux-image-3.10-3-rpi raspberrypi-bootloader-nokernel"
packages_found=
packages_debs=

required() {
    for i in $packages; do
        [[ $i = $1 ]] && return 0
    done

    return 1
}

allfound() {
    for i in $packages; do
        found=0

        for j in $packages_found; do
            [[ $i = $j ]] && found=1
        done

        [[ $found -eq 0 ]] && return 1
    done

    return 0
}

rm -rf packages/
mkdir packages
debug "clean directory"
cd packages

echo "Downloading package list..."
wget -O - $mirror/dists/$release/firmware/binary-armhf/Packages.bz2 | bunzip2 -c > Packages
wget -O - $mirror/dists/$release/main/binary-armhf/Packages.bz2 | bunzip2 -c >> Packages
debug "downloading package list in packages directory"

echo "Searching for required packages..."
while read k v
do
    current_filename=""
    if [ "$k" = "Package:" ]; then
        current_package=$v
        debug "package : $v"
    fi

    if [ "$k" = "Filename:" ]; then
        current_filename=$v
        debug "filename $v"
    fi

    if [ ! -z "$current_package" ] && [ ! -z "$current_filename" ]; then
        debug "we have package and filename"
        if required $current_package; then
            printf "  %-32s %s\n" $current_package `basename $current_filename`
            packages_debs="${mirror}${current_filename} ${packages_debs}"
            packages_found="$current_package $packages_found"
            debug $packages_found
            allfound && break
        fi

    fi
done < Packages
allfound || exit
debug "list of package to download: $packages_debs"
wget $packages_debs
cd ..
