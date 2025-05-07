# peerpom-netboot

TFTP_IP=10.42.0.1
BOOT_ORDER=0x21

cmdline.txt=console=serial0,115200 root=/dev/nfs nfsroot=192.168.1.10:/srv/nfs/rpi-root,vers=3 rw ip=dhcp rootwait


# Bootloader
TFTP_FOLDER=/srv/tftp

# ROOTFS 
NFS_FOLDER=/srv/nfs/rpi-root