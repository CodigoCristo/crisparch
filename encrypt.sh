
	disco="/dev/vda"
	dd if=/dev/zero of="${disco}" bs=100M count=10 status=progress
	parted ${disco} mklabel gpt
	sgdisk ${disco} -n=1:0:+100M -t=1:ef00
	sgdisk ${disco} -n=2:0:+4G -t=2:8200
	sgdisk ${disco} -n=3:0:0
	fdisk -l ${disco} > /tmp/partition
	echo ""
	cat /tmp/partition
	sleep 3

	partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"

	echo $partition | awk -F ' ' '{print $1}' >  boot-efi
	echo $partition | awk -F ' ' '{print $2}' >  swap-efi
	echo $partition | awk -F ' ' '{print $3}' >  root-efi


clear
printf "Clave de cifrado: "
read PASSPHRASE
echo "$PASSPHRASE"
sleep 5

echo -n "$PASSPHRASE" | cryptsetup --verbose -c aes-xts-plain64 --pbkdf argon2id --type luks2 -y luksFormat "$(cat root-efi)"
echo -n "$PASSPHRASE" | cryptsetup luksOpen "$(cat root-efi)" linux-cifrado

mkfs.ext4 /dev/mapper/linux-cifrado
mount /dev/mapper/linux-cifrado /mnt 

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

echo "Presiona ENTER para continuar..."
sleep 5

pacman -Sy reflector python --noconfirm

reflector --verbose --latest 5 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist

pacstrap /mnt base base-devel lvm2 wget efibootmgr grub nano reflector python neofetch

genfstab -p /mnt > /mnt/etc/fstab


arch-chroot /mnt /bin/bash -c "pacman -S dhcpcd networkmanager iwd net-tools ifplugd --noconfirm"
#ACTIVAR SERVICIOS
arch-chroot /mnt /bin/bash -c "systemctl enable dhcpcd NetworkManager"

echo "noipv6rs" >> /mnt/etc/dhcpcd.conf
echo "noipv6" >> /mnt/etc/dhcpcd.conf

arch-chroot /mnt /bin/bash -c "pacman -S linux linux-headers linux-firmware mkinitcpio --noconfirm"


sed -i '7d' /mnt/etc/mkinitcpio.conf
sed -i '7i MODULES=(ext4)' /mnt/etc/mkinitcpio.conf

sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block encrypt filesystems keyboard fsck)/g' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt /bin/bash -c 'mkinitcpio -P'

partition_root=$(cat root-efi)

sed -i '6d' /mnt/etc/default/grub
sed -i '6i GRUB_CMDLINE_LINUX="${partition_root}:linux-cifrado"' /mnt/etc/default/grub

echo '' 
echo 'Instalando EFI System >> bootx64.efi' 
arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --removable' 
echo '' 
echo 'Instalando UEFI System >> grubx64.efi' 
arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch'

arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"


reboot