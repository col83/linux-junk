#!/bin/bash

### color section
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

clear

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
timedatectl set-ntp true
hwclock --systohc

echo 'arch' > /etc/hostname

##################################################################################################

echo
read -p 'Change $root password (y/n): ' CHSH_PASS

if [[ ${CHSH_PASS} = y ]]; then
    echo 'New password for $root'
    echo
    passwd
fi

echo
read -p 'Create new user (y/n): ' USER_CREATE

if [[ ${USER_CREATE} = y ]]; then

    echo
    read -p 'New username: ' NEWUSER
    useradd -m -G wheel "${NEWUSER}"
    echo
    echo 'New password for' "${NEWUSER}"
    echo
    passwd "${NEWUSER}"
	
fi

##################################################################################################

echo
read -p 'edit visudo ? (y/n): ' VISUDO_EDIT

if [[ ${VISUDO_EDIT} = y ]]; then
    EDITOR=nano visudo
fi

## regenerate locales ############################################################################

echo
read -p 'Generate locale (y/n): ' GEN_LOCALE

if [[ ${GEN_LOCALE} = y ]]; then

    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
    echo 'ru_RU.UTF-8 UTF-8' >> /etc/locale.gen
    echo 'zh_CN.UTF-8' >> /etc/locale.gen
    locale-gen

    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
    echo 'KEYMAP=us' > /etc/vconsole.conf
	
fi

## my default network configuration ##############################################################

echo
read -p 'Setup network ? (first time configuration!!!) (y/n): ' NET_FIRST_CONFIG

if [[ ${NET_FIRST_CONFIG} = y ]]; then

    echo '127.0.0.1        localhost' > /etc/hosts
    echo '::1              localhost' >> /etc/hosts

    ### wpa_supplicant config

    echo 'mac_addr=1' >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo 'preassoc_mac_addr=1' >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    echo 'gas_rand_mac_addr=1' >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

    ### iwd config
	if [[ ! -d /etc/iwd/ ]]; then
        mkdir /etc/iwd
    fi

    echo '[General]' > /etc/iwd/main.conf
    echo 'EnableNetworkConfiguration=true' >> /etc/iwd/main.conf
    echo 'AddressRandomization=network' >> /etc/iwd/main.conf
    echo 'AddressRandomizationRange=full' >> /etc/iwd/main.conf
    echo 'ManagementFrameProtection=2' >> /etc/iwd/main.conf

    echo '' >> /etc/iwd/main.conf

    echo '[Network]' >> /etc/iwd/main.conf
    echo 'EnableIPv6=false' >> /etc/iwd/main.conf
    echo 'NameResolvingService=systemd' >> /etc/iwd/main.conf
    echo '[BandModifier2_4GHz=1.0]' >> /etc/iwd/main.conf
    echo '[BandModifier5GHz=1.0]' >> /etc/iwd/main.conf
    echo '[BandModifier6GHz=0.0]' >> /etc/iwd/main.conf

    ### network manager config for dnscrypt-proxy
    nmcli connection modify eth0 ipv4.dns 127.0.0.53
    nmcli connection modify eth0 ipv4.ignore-auto-dns yes
    nmcli connection modify wlan0 ipv4.dns 127.0.0.53
    nmcli connection modify wlan0 ipv4.ignore-auto-dns yes

    echo 'server=127.0.0.53' > /etc/NetworkManager/dnsmasq.d/custom.conf

    ### enable systemd services
    systemctl enable dhcpcd
    systemctl enable NetworkManager
    systemctl enable wpa_supplicant.service
    systemctl enable iwd.service

fi

# rebuild initramfs ##############################################################################

read -p 'Regen initramfs ? (y/n): ' INITRAMFS_REGEN

if [[ ${INITRAMFS_REGEN} = y ]]; then

    read -p 'Edit initcpio files ? (y/n): ' INITCPIO_FILES_EDIT
    
    if [[ ${INITCPIO_FILES_EDIT} = y ]]; then
        nano /etc/mkinitcpio.conf
        nano /etc/mkinitcpio.d/linux-*.preset
    fi


    if [[ ! -f /boot/vmlinuz-linux ]]; then
        cp /usr/lib/modules/**/vmlinuz /boot/vmlinuz-linux
    fi

    mkinitcpio -P

fi

## bootloaders ###################################################################################

bootloader_grub() {

if [[ ! -d /boot/efi/grub/ ]]; then
    grub-install --efi-directory=/boot/
    grub-mkconfig -o /boot/grub/grub.cfg
fi
	
read -p 'Edit grub bootloader conf ? (y/n): ' EDIT_BOOTCTL_CONF
if [[ ${EDIT_BOOTCTL_CONF} = y ]]; then
    nano /boot/grub/grub.cfg
fi

}

bootloader_systemd() {

bootctl install

if [[ -f /boot/efi/loader/loader.conf ]]; then
    cp /usr/share/systemd/bootctl/loader.conf /boot/efi/loader/
    cp /usr/share/systemd/bootctl/arch.conf /boot/efi/loader/entries/
fi

read -p 'Edit systemd bootloader conf ? (y/n): ' EDIT_BOOTCTL_CONF
if [[ ${EDIT_BOOTCTL_CONF} = y ]]; then
    nano /boot/efi/loader/loader.conf
    nano /boot/efi/loader/entries/arch.conf
fi

}

echo
read -p 'Install bootloader ? (y/n): ' BOOTLOADER_INSTALL

if [[ ${BOOTLOADER_INSTALL} = y ]]; then
    echo '(1) grub (2) systemd-boot (unfinished - not work)'
    echo
    read -p 'Select bootloader: ' BOOTLOADER_SELECT

    if [[ ${BOOTLOADER_SELECT} = 1 ]]; then
        echo
        bootloader_grub
    else
        echo
        bootloader_grub
    fi

fi

## desktop enviroment ############################################################################

echo
read -p 'Install Desktop Enviroment ? (y/n): ' DE_INSTALL

if [[ ${DE_INSTALL} = y ]]; then

    pacman -Syy

    echo
    echo '(1) gnome (minimal) (2) hyprland (3) cosmic'
    read -p 'Select DE: ' DE_SELECT

    if [[ ${DE_SELECT} = 1 ]]; then

        sudo pacman -S --needed - < ./DArch/DE.d/gnome.txt || exit 1 && echo 'error. try again'

    fi

    if [[ ${DE_SELECT} = 2 ]]; then

        sudo pacman -S --needed - < ./DArch/DE.d/hyprland.txt || exit 1 && echo 'error. try again'

    fi
	
    if [[ ${DE_SELECT} = 3 ]]; then

    sudo pacman -S --needed cosmic || exit 1 && echo 'error. try again'

    fi

fi

##################################################################################################

echo; echo
