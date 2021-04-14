
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
sleep 3