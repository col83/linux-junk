#!/bin/bash

### color section
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

clear

#FIXED MIRRORLIST

URL='Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch'
echo ${URL} > /etc/pacman.d/mirrorlist

# PACKAGES #########################################################################################################

pkg_nvme_support="libblockdev-nvme libnvme nvme-cli nvmetcli"

pkg_sys="archiso base dfc fatresize gptfdisk htop less linux linux-firmware mkinitcpio-archiso ntfs-3g pv sudo"

pkg_boot="grub efibootmgr mkinitcpio dracut"

pkg_dev="base-devel devtools"

pkg_shell="bash-completion zsh"

pkg_network="bind dhcpcd iw iwd networkmanager wireless_tools wireless-regdb"

pkg_editor="micro nano vim"


# INSTALLATION FUNCTIONS ###########################################################################################

reflector_check() {

    if [[ -f /bin/reflector ]]; then

        systemctl stop reflector.service
        rm -rf /etc/xdg/reflector/

    fi

}


pacstrap_init() {

    pacstrap -K /mnt ${pkg_nvme_support} ${pkg_sys} ${pkg_boot} ${pkg_dev} ${pkg_shell} ${pkg_network} ${pkg_editor}

    genfstab -U /mnt >> /mnt/etc/fstab
    cp /mnt/etc/fstab /mnt/etc/fstab.bak

    echo ${URL} > /mnt/etc/pacman.d/mirrorlist
    arch-chroot /mnt /bin/bash -c "chattr +i /etc/pacman.d/mirrorlist"

    cp ./zero-post.sh /mnt/root/
    cp -r ./DArch/ /mnt/root/DArch/

    echo; echo; echo "Type new $root password"; echo
    arch-chroot /mnt /bin/bash -c "passwd"

}


arch-chroot_step() {

    echo; echo; echo; echo 'WARNING: YOU NOW IN CHROOT SYSTEM!'; echo		
    arch-chroot /mnt

}

reflector_check
pacstrap_init && arch-chroot_step
