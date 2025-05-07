#!/bin/bash

echo "Start Building Net-Boot PXE Image !!!"

# sudo apt update
# sudo apt install dnsmasq tftpd-hpa nfs-kernel-server -y


echo "Creating Backup of dnsmasq.conf..."
sudo cp -r /etc/dnsmasq.conf /etc/dnsmasq.conf.bak && sudo cp -r /etc/dnsmasq.conf . 
sleep 1;

echo "Deleting current /etc/dnsmasq.conf..."
sudo rm -rf /etc/dnsmasq.conf

sleep 1;


echo "Enter new dnsmasq.conf settings..."
sudo ifconfig
read -p "Enter your ip: " ip
read -p "Enter ip-range: " ip_range
read -p "Enter Device: " dev
sleep 1;
echo "Creating dnsmasq.conf..."
sudo cat <<EOF > /etc/dnsmasq.conf
interface=$dev
bind-interfaces
dhcp-range=$ip,$ip_range,12h
enable-tftp
tftp-root=/srv/tftp
dhcp-boot=bootcode.bin
EOF
sleep 1;
echo "Creating TFTP-Folder: /srv/tftp"
sudo mkdir -p /srv/tftp
sleep 1;
echo "Creating NFS-Folder (ROOTFS): /srv/nfs"
sudo mkdir -p /srv/nfs/rpi-root
sleep 1;
echo "Backing up /etc/exports..."
mv /etc/exports /etc/exports.bak
echo "Removing current /etc/exports..."
rm -rf /etc/exports
sleep 1;
echo "Creating NFS-Exports: /etc/exports ..."
echo -e "/srv/nfs/rpi-root $ip/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
sleep 1;
echo "Aktualisiere NFS-Exporttabelle!..."
sudo exportfs -a
sleep 1;
echo "wechsel zu tftp verzeichnis!"
cd /srv/tftp
echo "Downloade Bootdatein!..."
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/bootcode.bin
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/start4.elf
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/fixup4.dat
sudo wget https://github.com/raspberrypi/firmware/raw/master/boot/kernel8.img
sleep 1;
echo "Creating cmdline.txt..."
cat <<EOF > /srv/tftp/cmdline.txt
console=serial0,115200 root=/dev/nfs nfsroot=$ip:/srv/nfs/rpi-root,vers=3 rw ip=dhcp rootwait
EOF
sleep 1;
echo "Erstelle Verzeichnis für EEPROM Konfiguration..."
mkdir -p bootloader
cd bootloader
sleep 1;
echo "Kopiere neuste EEPROM DATEI!"
wget https://github.com/arm-firmware-hackers/build_netboot/blob/main/pieeprom-2025-04-07.bin .
sleep 1;
echo "Erstelle Konfiguration für EEPROM !..."
sleep 1;
mv bootconf.txt bootconf.txt.bak
rm -rf bootconf.txt

echo "Erstelle Konfiguration für EEPROM !..."
cat <<EOF > bootconf.txt
[all]
BOOT_ORDER=0x21
TFTP_IP=$ip
EOF

chmod a+x -R ./*
echo "Kombiniere die EEPROM-Datei mit der Konfiguration:"
./rpi-eeprom-config --out pieeprom-netboot.bin --config bootconf.txt pieeprom-2025-04-07.bin
sleep 1;
echo "DONE: YOUR IMAGE IS: pieeprom-netboot.bin !!!"
echo "Copying pieeprom-netboot.bin to /srv/tftp !!!"
sudo cp pieeprom-netboot.bin /srv/tftp/
echo "Copying pieeprom-netboot.bin to $(pwd)/output/ !!!"
sudo cp pieeprom-netboot.bin $(pwd)/output/
sleep 1;
echo "STORED: pieeprom-netboot.bin in $(pwd)/output/ !..."
sleep 1;
echo "Schreibe EEPROM auf SD-Card !!!"
echo "List of devices:"
sudo fdisk -l
read -p "Enter the device name (e.g., /dev/sdX): " device_name
sleep 1;
echo "Writing pieeprom-netboot.bin to $device_name..."
sudo dd if=pieeprom-netboot.bin of=$device_name bs=512 seek=1
sync
echo "DONE: pieeprom-netboot.bin written to $device_name !..."
echo "Unmounting $device_name..."
sudo umount $device_name
echo "Unmounted $device_name !..."
sleep 1;
echo "Starting dnsmasq service..."
sudo systemctl restart dnsmasq
echo "dnsmasq service started !..."
sleep 1;
echo "Starting NFS service..."
sudo systemctl restart nfs-kernel-server
echo "NFS service started !..."
sleep 1;
echo "Starting tftpd-hpa service..."
sudo systemctl restart tftpd-hpa
echo "tftpd-hpa service started !..."
sleep 1;
echo "Net-Boot PXE Image created successfully !..."
sleep 1;
echo "Yo can now boot your Raspberry Pi from the network !..."
sleep 1;
echo "Please make sure to configure your DHCP server to point to the TFTP server !..."
sleep 1;
echo "If you have any questions, please contact us !..."
echo "DONE !!!"
echo "Have a nice day !..."
echo "Bye !..."