#!/bin/bash

### color section
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

clear

#FIXED MIRRORLIST

URL='Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch'
echo ${URL} > /etc/pacman.d/mirrorlist

##############################################################################################################################################################################


# video driver section #######################################################################################################################################################

video_AMD="xf86-video-amdgpu amdvlk"

video_INTEL="intel-media-driver vulkan-intel intel-compute-runtime"

video_NVIDIA="nvidia"

pkg_gfx_driver=""


gfx_driver_select() {

    echo '(1) amd (2) intel (3) nvidia'
    read -p 'Select graphics driver: ' GFX_DRIVER_SET
    
    if [[ ${GFX_DRIVER_SET} = 1 ]]; then
        pkg_gfx_driver="${video_AMD}"
    fi

    if [[ ${GFX_DRIVER_SET} = 2 ]]; then
        pkg_gfx_driver="${video_INTEL}"
    fi

    if [[ ${GFX_DRIVER_SET} = 3 ]]; then
        pkg_gfx_driver="${video_NVIDIA}"
    fi

}

echo
gfx_driver_select

# PACKAGES ###################################################################################################################################################################

pkg_nvme_support="libblockdev-nvme libnvme nvme-cli nvmetcli"

pkg_sys="7zip archiso base linux linux-firmware man-db man-pages mkinitcpio-archiso ntfs-3g unzip wget zip"

pkg_boot="grub efibootmgr mkinitcpio dracut"

pkg_dev="base-devel devtools clang llvm rust"

pkg_shell="bash-completion zsh"

pkg_network="bind dhcpcd dnscrypt-proxy dnsmasq iw iwd netscanner network-manager-applet wireless_tools wireless-regdb"

pkg_editor="leafpad nano"

pkg_boredom="aircrack-ng cowpatty hashcat hcxdumptool hcxtools hydra macchanger wireshark-cli"

pkg_fonts="gnu-free-fonts ttf-dejavu"


# INSTALLATION FUNCTIONS #####################################################################################################################################################

reflector_check() {

    if [[ -f /bin/reflector ]]; then

        systemctl stop reflector.service
        rm -rf /etc/xdg/reflector/

    fi

}


pacstrap_init() {

    pacstrap -K /mnt ${pkg_nvme_support} ${pkg_sys} ${pkg_boot} ${pkg_dev} ${pkg_shell} ${pkg_network} ${pkg_editor} ${pkg_boredom} ${pkg_fonts} ${pkg_gfx_driver}

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
