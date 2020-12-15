#!/bin/bash

#Sistema en español en liveCD
clear
echo ""
echo "Sistema en español"
echo ""
echo "es_ES.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
export LANG=es_ES.UTF-8
echo ""
sleep 3

#Actualización de llaves y mirroslist
clear
pacman -Sy archlinux-keyring --noconfirm 
clear
pacman -Sy reflector python rsync --noconfirm 
sleep 3
clear
echo ""
echo "Actualizando lista de MirrorList"
echo ""
reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
clear
cat /etc/pacman.d/mirrorlist
sleep 3
clear

#Disco
echo "print devices" | parted | grep /dev/ | awk '{if (NR!=1) {print}}'
echo ''
read -p "Introduce tu disco a instalar Arch: " disco

echo ''
echo "Selección de Disco: $disco"
sleep 3
echo ''

uefi=$( ls /sys/firmware/efi/ | grep -ic efivars )

if [ $uefi == 1 ]
then
	clear
	echo "Sistema UEFI"
	echo ""
	#Fuente: https://wiki.archlinux.org/index.php/GPT_fdisk
	#Metodo con EFI - SWAP - ROOT - HOME
	sgdisk --zap-all ${disco}
	parted ${disco} mklabel gpt
	sgdisk ${disco} -n=1:0:+200M -t=1:ef00
	sgdisk ${disco} -n=2:0:+4G -t=2:8200
	sgdisk ${disco} -n=3:0:+50G -t=3:8300
	sgdisk ${disco} -n=4:0:0
	fdisk -l ${disco} > /tmp/partition
	echo ""
	echo ""
	cat /tmp/partition
	sleep 3

	partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"

	echo $partition | awk -F ' ' '{print $1}' >  boot-efi
	echo $partition | awk -F ' ' '{print $2}' >  swap-efi
	echo $partition | awk -F ' ' '{print $3}' >  root-efi
	echo $partition | awk -F ' ' '{print $4}' >  home-efi

	echo ""
	echo "Partición EFI es:" 
	cat boot-efi
	echo ""
	echo "Partición SWAP es:"
	cat swap-efi
	echo ""
	echo "Partición ROOT es:"
	cat root-efi
	echo ""
	echo "Partición HOME es:"
	cat home-efi
	sleep 4

	clear
	echo ""
	echo "Formateando Particiones"
	echo ""
	mkfs.ext4 $(cat root-efi) 
	mount $(cat root-efi) /mnt 

	mkdir -p /mnt/home
	mkfs.ext4 $(cat home-efi) 
	mount $(cat home-efi) /mnt/home

	mkdir -p /mnt/efi 
	mkfs.fat -F 32 $(cat boot-efi) 
	mount $(cat boot-efi) /mnt/efi 

	mkswap $(cat swap-efi) 
	swapon $(cat swap-efi)

	clear
	echo ""
	echo "Revise en punto de montaje en MOUNTPOINT"
	echo ""
	lsblk -l
	sleep 4
	clear

#---Metodo con EFI - SWAP - ROOT--------
#	sgdisk --zap-all ${disco}
#	parted ${disco} mklabel gpt
#	sgdisk ${disco} -n=1:0:+100M -t=1:ef00
#	sgdisk ${disco} -n=2:0:+4G -t=2:8200
#	sgdisk ${disco} -n=3:0:0
#	fdisk -l ${disco} > /tmp/partition
#	echo ""
#	cat /tmp/partition
#	sleep 3
#
#	partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"
#
#	echo $partition | awk -F ' ' '{print $1}' >  boot-efi
#	echo $partition | awk -F ' ' '{print $2}' >  swap-efi
#	echo $partition | awk -F ' ' '{print $3}' >  root-efi
#
#	echo ""
#	echo "Partición EFI es:" 
#	cat boot-efi
#	echo ""
#	echo "Partición SWAP es:"
#	cat swap-efi
#	echo ""
#	echo "Partición ROOT es:"
#	cat root-efi
#	echo ""
#	echo "Partición HOME es:"
#	cat home-efi
#	sleep 3
#
#	clear
#	echo ""
#	echo "Formateando Particiones"
#	echo ""
#	mkfs.ext4 $(cat root-efi) 
#	mount $(cat root-efi) /mnt 
#
#	mkdir -p /mnt/home
#	mkfs.ext4 $(cat home-efi) 
#	mount $(cat home-efi) /mnt/home
#
#	mkdir -p /mnt/efi 
#	mkfs.fat -F 32 $(cat boot-efi) 
#	mount $(cat boot-efi) /mnt/efi 
#
#	mkswap $(cat swap-efi) 
#	swapon $(cat swap-efi)
#
#	clear
#	echo ""
#	echo "Revise en punto de montaje en MOUNTPOINT"
#	echo ""
#	lsblk -l
#	sleep 3


else
	clear
	echo ""
	echo "Sistema BIOS"
	echo ""

	#---Metodo con BIOS - SWAP - ROOT- HOME-------
	sgdisk --zap-all ${disco}
	#+100M particion boot
	#+4G	particion swap
	#+20G	particion root
	#""		partición home
	#Cambien valores si desean
	(echo o; echo n; echo p; echo 1; echo ""; echo +100M; echo n; echo p; echo 2; echo ""; echo +4G; echo n; echo p; echo 3; echo ""; echo +20G; echo n; echo p; echo 4; echo ""; echo ""; echo t; echo 2; echo 82; echo a; echo 1; echo w; echo q) | fdisk ${disco}
	
	fdisk -l ${disco} > /tmp/partition 
	cat /tmp/partition
	sleep 3

	partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"

	echo $partition | awk -F ' ' '{print $1}' >  boot-bios
	echo $partition | awk -F ' ' '{print $2}' >  swap-bios
	echo $partition | awk -F ' ' '{print $3}' >  root-bios

	echo ""
	echo "Partición BOOT es:" 
	cat boot-bios
	echo ""
	echo "Partición SWAP es:"
	cat swap-bios
	echo ""
	echo "Partición ROOT es:"
	cat root-bios
	sleep 3

	clear
	echo ""
	echo "Formateando Particiones"
	echo ""
	mkfs.ext4 $(cat root-bios) 
	mount $(cat root-bios) /mnt 

	mkdir -p /mnt/boot
	mkfs.ext4 $(cat boot-bios) 
	mount $(cat boot-bios) /mnt/boot

	mkswap $(cat swap-bios) 
	swapon $(cat swap-bios)

	clear
	echo ""
	echo "Revise en punto de montaje en MOUNTPOINT"
	echo ""
	lsblk -l
	sleep 4
	clear


#---Metodo con BIOS - SWAP - ROOT-------
#	clear
#	echo ""
#	echo "Sistema BIOS"
#	echo ""
#	sgdisk --zap-all ${disco}
#	(echo o; echo n; echo p; echo 1; echo ""; echo +100M; echo n; echo p; echo 2; echo ""; echo +4G; echo n; echo p; echo 3; echo ""; echo ""; echo t; echo 2; echo 82; echo a; echo 1; echo w; echo q) | fdisk ${disco}
#	fdisk -l ${disco} > /tmp/partition 
#	cat /tmp/partition
#	sleep 3
#
#	partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"
#
#	echo $partition | awk -F ' ' '{print $1}' >  boot-bios
#	echo $partition | awk -F ' ' '{print $2}' >  swap-bios
#	echo $partition | awk -F ' ' '{print $3}' >  root-bios
#
#	echo ""
#	echo "Partición BOOT es:" 
#	cat boot-bios
#	echo ""
#	echo "Partición SWAP es:"
#	cat swap-bios
#	echo ""
#	echo "Partición ROOT es:"
#	cat root-bios
#	sleep 3
#
#	clear
#	echo ""
#	echo "Formateando Particiones"
#	echo ""
#	mkfs.ext4 $(cat root-bios) 
#	mount $(cat root-bios) /mnt 
#
#	mkdir -p /mnt/boot
#	mkfs.ext4 $(cat boot-bios) 
#	mount $(cat boot-bios) /mnt/boot
#
#	mkswap $(cat swap-bios) 
#	swapon $(cat swap-bios)
#
#	clear
#	echo ""
#	echo "Revise en punto de montaje en MOUNTPOINT"
#	echo ""
#	lsblk -l
#	sleep 4
#	clear
	
fi



echo ""
echo "Instalando Sistema base"
echo ""
pacstrap /mnt base base-devel nano reflector python rsync
clear


echo ""
echo "Archivo FSTAB"
echo ""
echo "genfstab -p /mnt >> /mnt/etc/fstab"
echo ""

genfstab -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
sleep 4
clear


#CONFIGURANDO PACMAN
sed -i 's/#Color/Color/g' /mnt/etc/pacman.conf
sed -i 's/#TotalDownload/TotalDownload/g' /mnt/etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/g' /mnt/etc/pacman.conf

sed -i "37i ILoveCandy" /mnt/etc/pacman.conf

sed -i '93d' /mnt/etc/pacman.conf
sed -i '94d' /mnt/etc/pacman.conf
sed -i "93i [multilib]" /mnt/etc/pacman.conf
sed -i "94i Include = /etc/pacman.d/mirrorlist" /mnt/etc/pacman.conf
clear


#hosts
clear
#NOmbre de computador
hostname=alvarado

echo "$hostname" > /mnt/etc/hostname
echo "127.0.1.1 $hostname.localdomain $hostname" > /mnt/etc/hosts
clear
echo "Hostname: $(cat /mnt/etc/hostname)"
echo ""
echo "Hosts: $(cat /mnt/etc/hosts)"
echo ""
clear


#USUARIO Y ADMIN
rootpasswd=123
user=cristo
userpasswd=123

arch-chroot /mnt /bin/bash -c "(echo $rootpasswd ; echo $rootpasswd) | passwd root"
arch-chroot /mnt /bin/bash -c "useradd -m -g users -s /bin/bash $user"
arch-chroot /mnt /bin/bash -c "(echo $userpasswd ; echo $userpasswd) | passwd $user"

sed -i "80i $user ALL=(ALL) ALL"  /mnt/etc/sudoers


#ACTUALIZACIÓN DE IDIOMA Y ZONA HORARIA
echo "" 
echo -e ""
echo -e "\t\t\t| Actualizando Idioma del Sistema |"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo -e ""

echo "es_PE.UTF-8 UTF-8" > /mnt/etc/locale.gen
arch-chroot /mnt /bin/bash -c "locale-gen" 
echo "LANG=es_PE.UTF-8" > /mnt/etc/locale.conf
echo ""
cat /mnt/etc/locale.conf 
cat /mnt/etc/locale.gen
sleep 4
echo ""
arch-chroot /mnt /bin/bash -c "export $(cat /mnt/etc/locale.conf)" 
export $(cat /mnt/etc/locale.conf)
arch-chroot /mnt /bin/bash -c "sudo -u $user export $(cat /etc/locale.conf)"
export $(cat /mnt/etc/locale.conf)
sleep 3

clear
arch-chroot /mnt /bin/bash -c "pacman -Sy curl --noconfirm"
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/$(curl https://ipapi.co/timezone) /etc/localtime"

#opcional
echo "KEYMAP=es" > /mnt/etc/vconsole.conf 
cat /mnt/etc/vconsole.conf 
clear

arch-chroot /mnt /bin/bash -c "timedatectl set-timezone $(curl https://ipapi.co/timezone)"
arch-chroot /mnt /bin/bash -c "pacman -S ntp --noconfirm"
clear
arch-chroot /mnt /bin/bash -c "ntpd -qg"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
sleep 3

clear
echo ""
echo "Actualizando lista de MirrorList"
echo ""
arch-chroot /mnt /bin/bash -c "reflector --verbose --latest 10 --sort rate --save /etc/pacman.d/mirrorlist"
clear
cat /mnt/etc/pacman.d/mirrorlist
sleep 3
clear

#Instalación del kernel
arch-chroot /mnt /bin/bash -c "pacman -S linux-firmware linux linux-headers mkinitcpio --noconfirm"

arch-chroot /mnt /bin/bash -c "pacman -S gnome-shell gdm gnome-control-center gnome-backgrounds gnome-tweaks --noconfirm"
arch-chroot /mnt /bin/bash -c "systemctl enable gdm"

uefi=$( ls /sys/firmware/efi/ | grep -ic efivars )

if [ $uefi == 1 ]
then
clear
arch-chroot /mnt /bin/bash -c "pacman -S grub efibootmgr os-prober dosfstools --noconfirm"
echo '' 
echo 'Instalando EFI System >> bootx64.efi' 
arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --removable' 
echo '' 
echo 'Instalando UEFI System >> grubx64.efi' 
arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch'
######
sed -i "6iGRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"" /mnt/etc/default/grub
sed -i '7d' /mnt/etc/default/grub
######
echo ''
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
echo '' 
echo 'ls -l /mnt/efi' 
ls -l /mnt/efi 
echo '' 
echo 'Lea bien que no tenga ningún error marcado' 
echo '> Confirme tener las IMG de linux para el arranque' 
echo '> Confirme tener la carpeta de GRUB para el arranque' 
sleep 4

else
clear
arch-chroot /mnt /bin/bash -c "pacman -S grub os-prober --noconfirm"
echo '' 
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc $disco"

######
sed -i "6iGRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"" /mnt/etc/default/grub
sed -i '7d' /mnt/etc/default/grub
######
echo ''
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
echo '' 
echo 'ls -l /mnt/boot' 
ls -l /mnt/boot 
echo '' 
echo 'Lea bien que no tenga ningún error marcado' 
echo '> Confirme tener las IMG de linux para el arranque' 
echo '> Confirme tener la carpeta de GRUB para el arranque' 

fi





#Instalación de programas:
arch-chroot /mnt /bin/bash -c "pacman -S dhcpcd networkmanager iwd net-tools ifplugd --noconfirm"
#ACTIVAR SERVICIOS
arch-chroot /mnt /bin/bash -c "systemctl enable dhcpcd NetworkManager"

echo "noipv6rs" >> /mnt/etc/dhcpcd.conf
echo "noipv6" >> /mnt/etc/dhcpcd.conf

#Wifi
#arch-chroot /mnt /bin/bash -c "pacman -S iw wireless_tools wpa_supplicant dialog wireless-regdb --noconfirm"

#Bluutuuu
#arch-chroot /mnt /bin/bash -c "pacman -S bluez bluez-utils pulseaudio-bluetooth"

#Video
arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-fbdev mesa mesa-libgl qemu-guest-agent --noconfirm"
#NVIDIA > xf86-video-nouveau
#AMD 	> xf86-video-ati
#INTEL 	> xf86-video-intel

#SHELL
arch-chroot /mnt /bin/bash -c "pacman -S zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions --noconfirm"
SH=zsh
arch-chroot /mnt /bin/bash -c "chsh -s /bin/$SH"
arch-chroot /mnt /bin/bash -c "chsh -s /usr/bin/$SH $user"
arch-chroot /mnt /bin/bash -c "chsh -s /bin/$SH $user"

#Xorg
#arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-apps xorg-xinit xorg-twm xterm xorg-xclock --noconfirm"

#Utilidades
arch-chroot /mnt /bin/bash -c "pacman -S git wget neofetch lsb-release xdg-user-dirs --noconfirm"
arch-chroot /mnt /bin/bash -c "xdg-user-dirs-update"
clear
echo ""
arch-chroot /mnt /bin/bash -c "ls -l /home/$user"
sleep 5


#AUDIO
arch-chroot /mnt /bin/bash -c "pacman -S pulseaudio pavucontrol --noconfirm"

#Tipografias
arch-chroot /mnt /bin/bash -c "pacman -S gnu-free-fonts ttf-hack ttf-inconsolata gnome-font-viewer --noconfirm"

#NAVEGADOR WEB
#arch-chroot /mnt /bin/bash -c "pacman -S firefox --noconfirm"
#chromium
#opera
#vivaldi

#establecer formato de teclado
	  clear
            keymap="latam"

      arch-chroot /mnt /bin/bash -c "localectl --no-convert set-x11-keymap $keymap"
      arch-chroot /mnt /bin/bash -c "setxkbmap -layout $keymap"

      echo -e 'Section "InputClass"' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
      echo -e 'Identifier "system-keyboard"' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
      echo -e 'MatchIsKeyboard "on"' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
      echo -e 'Option "XkbLayout" "latam"' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
      echo -e 'EndSection' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
      echo ""
      cat /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
      sleep 5
      clear



#DESMONTAR Y REINICIAR
umount -R /mnt
swapoff -a
	  clear
      echo ""
      echo "Visita: https://t.me/ArchLinuxCristo"
      sleep 5
reboot