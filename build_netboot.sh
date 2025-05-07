#!/bin/bash

echo "Start Building Net-Boot PXE Image !!!"

# sudo apt update
# sudo apt install dnsmasq tftpd-hpa nfs-kernel-server -y


echo "Creating Backup of dnsmasq.conf..."
sudo cp -r /etc/dnsmasq.conf /etc/dnsmasq.conf.bak && sudo cp -r /etc/dnsmasq.conf . 


sudo rm -rf /etc/dnsmasq.conf

read -p "Enter your ip: " ip
read -p "Enter ip-range: " ip_range

echo "Creating dnsmasq.conf..."
sudo cat <<EOF > /etc/dnsmasq.conf
interface=eth0
bind-interfaces
dhcp-range=$ip,$ip_range,12h
enable-tftp
tftp-root=/srv/tftp
dhcp-boot=bootcode.bin
EOF



echo "Creating TFTP-Folder: /srv/tftp"
sudo mkdir -p /srv/tftp



echo "Creating NFS-Folder (ROOTFS): /srv/nfs"
sudo mkdir -p /srv/nfs/rpi-root


mv /etc/exports /etc/exports.bak
rm -rf /etc/exports

echo "Creating NFS-Exports..."
echo -e "/srv/nfs/rpi-root $ip/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports


echo "Aktualisiere NFS-Exporttabelle!..."
sudo exportfs -a

echo "wechsel zu tftp verzeichnis!"
cd /srv/tftp
echo "Downloade Bootdatein!..."
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/start4.elf
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/fixup4.dat
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/kernel8.img

echo "Creating cmdline.txt..."
cat <<EOF > /srv/tftp/cmdline.txt
console=serial0,115200 root=/dev/nfs nfsroot=$ip:/srv/nfs/rpi-root,vers=3 rw ip=dhcp rootwait
EOF

echo "Erstelle Verzeichnis für EEPROM Konfiguration..."
mkdir -p bootloader
cd bootloader

echo "Kopiere neuste EEPROM DATEI!"
cp -r /home/zerobyte/Entwicklung/Geräte-Entwicklung/EntwicklerBoards/Raspberry-Pi/Raspberry-Pi-5/Projekte-Index/arm-firmware-hackers_development/firmware_builder/resources/build_netboot/pieeprom-2025-04-07.bin .

echo "Erstelle Konfiguration für EEPROM !..."

mv bootconf.txt bootconf.txt.bak
rm -rf bootconf.txt

re

echo "Erstelle Konfiguration für EEPROM !..."
cat <<EOF > bootconf.txt
[all]
BOOT_ORDER=0x21
TFTP_IP=
EOF

chmod a+x -R ./*
echo "Kombiniere die EEPROM-Datei mit der Konfiguration:"
./rpi-eeprom-config --out pieeprom-netboot.bin --config bootconf.txt pieeprom-2025-04-07.bin


echo "DONE: YOUR IMAGE IS: pieeprom-netboot.bin !!!"
echo "Copying pieeprom-netboot.bin to /srv/tftp !!!"
sudo cp pieeprom-netboot.bin /srv/tftp/
sudo cp pieeprom-netboot.bin $(pwd)/output/


echo "pieeprom-netboot.bin is in $(pwd)/output/ !..."


echo "Schreibe EEPROM auf SD-Card !!!"
echo "List of devices:"
sudo fdisk -l
read -p "Enter the device name (e.g., /dev/sdX): " device_name

echo "Writing pieeprom-netboot.bin to $device_name..."
sudo dd if=pieeprom-netboot.bin of=$device_name bs=512 seek=1
