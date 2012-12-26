#!/bin/sh

# set verbose to "1" to print 
VERBOSE=1

# ================================================================== #
#     Configure if the SW images are kept in different directories
# ================================================================== #
# no padding uboot
UBOOTMFG=./u-boot-no-padding-mfg.bin  # modify to tell where is the no padding uboot
PUBOOTMFG=./u-boot-mfg.bin
# kernel
KERNEL=./uImage # modify to tell where is kernel
INITRAMFS=./initramfs.cpio.gz.uboot 

PUBOOT=./u-boot.bin
UBOOT=./u-boot-no-padding.bin 
PRAMDISKIMG=./ramdisk.img
RAMDISKIMG=./uramdisk.img
ROOTFSIMG=./system.img 
RECOVERYIMG=./recovery.img 
INPUTPARAM=./fdisk-u.input


MOUNTMNT=/mnt



# ================================================================== #
help() {

local BN=`basename $0`
cat << EOF
usage $BN <option> device_node

options:
  -h				displays this help message
  -s				only get partition size
EOF

}
# ================================================================== #
check_if_root() {
# check the if root?
USERID=`id -u`
if [ ${USERID} -ne "0" ]; then
	echo "you're not root?"
	exit 1
fi
}
# ================================================================== #
get_imagesizes() {
# partition size in MB
BOOT_ROM_SIZE=30
}
# ================================================================== #
umount_partitions () {
        local PARTITIONS=`mount | grep -c ${NODE}`
        if [ "${PARTITIONS}" -gt 0 ];then
                echo "umount partitions of ${NODE}..."
                umount `mount | grep  ${NODE} | awk '{printf("%s* ",$3)}'`
                sleep 2
        else
                echo "${NODE} does not have partitions mounted..."
        fi
}
# ================================================================== #
cal_partitions_size () {

# call sfdisk to create partition table
# get total card size
TOTAL_SIZE=`sfdisk -s ${NODE}`
TOTAL_SIZE=`expr ${TOTAL_SIZE} / 1024`
local ROM_SIZE=`expr ${BOOT_ROM_SIZE}`
BVFAT_SIZE=`expr ${TOTAL_SIZE} - ${ROM_SIZE} `
VFAT_SIZE=`expr ${TOTAL_SIZE} - ${ROM_SIZE} - 10 `

 
if [ "${VERBOSE}" -eq "1" ];then
cat << EOF
TOTAL_SIZE : ${TOTAL_SIZE}MB
ROM_SIZE   : ${ROM_SIZE}MB
BVFAT_SIZE : ${BVFAT_SIZE}MB
VFAT_SIZE  : ${VFAT_SIZE}MB
EOF
fi

}
# ================================================================== #
print_sdcard_partition() {
cat << EOF
TOTAL_SIZE          : ${TOTAL_SIZE}MB
   ROM_SIZE         : ${BOOT_ROM_SIZE}MB
[1]VFAT_SIZE        : ${VFAT_SIZE}MB
EOF
}
# ================================================================== #
sfdisk_sdcard() {
# destroy the partition table
dd if=/dev/zero of=${NODE} bs=1024 count=30

umount_partitions

sfdisk --force -uM ${NODE} << EOF
,${BVFAT_SIZE},b
EOF

umount_partitions

sfdisk --force -uM ${NODE} -N1 << EOF
${BOOT_ROM_SIZE},${VFAT_SIZE},b
EOF

}

format_sdcard() {
# format the SDCARD/DATA/CACHE partition
PART=""
echo ${NODE} | grep mmcblk > /dev/null
if [ "$?" -eq "0" ]; then
	PART="p"
fi

umount_partitions

mkfs.vfat ${NODE}${PART}1
}
# ================================================================== #
program_sdcard() {
echo "copy uboot mfg..."
dd if=${PUBOOTMFG} of=${UBOOTMFG} bs=1024 skip=1 && sync && sync
dd if=${UBOOTMFG} of=${NODE} bs=1K seek=1 && sync && sync
echo "copy linux kernel..."
dd if=${KERNEL} of=${NODE} bs=1M seek=1 && sync && sync
echo "copy ramdisk..."
dd if=${INITRAMFS} of=${NODE} bs=1M seek=6 && sync && sync
mkimage -A arm -O linux -T ramdisk -C none -a 0x70308000 -n "Android Root Filesystem" -d ${PRAMDISKIMG} ${RAMDISKIMG}
mount ${NODE}${PART}1  ${MOUNTMNT} -t vfat
dd if=${PUBOOT} of=${UBOOT} bs=1024 skip=1 && sync && sync
cp ${UBOOT} ${MOUNTMNT}/
cp ${RAMDISKIMG} ${MOUNTMNT}/
cp ${KERNEL} ${MOUNTMNT}/
cp ${ROOTFSIMG} ${MOUNTMNT}/
cp ${RECOVERYIMG} ${MOUNTMNT}/
cp ${INPUTPARAM} ${MOUNTMNT}/
umount ${MOUNTMNT}
}
# ================================================================== #
#    MAIN
# ================================================================== #

check_if_root

MOREOPTIONS=1
NODE="na"
CAL_ONLY=0

while [ "$MOREOPTIONS" = 1 -a $# -gt 0 ]; do
	case $1 in
		-h) help; exit ;;
		-s) CAL_ONLY=1 ;;
		*)  MOREOPTIONS=0; NODE=$1 ;;
	esac
	[ "$MOREOPTIONS" = 0 ] && [ $# -gt 1 ] && help && exit
	[ "$MOREOPTIONS" = 1 ] && shift
done

if [ ! -e ${NODE} ]; then
	help
	exit
fi

get_imagesizes

cal_partitions_size

if [ "${CAL_ONLY}" -eq "1" ]; then
	print_sdcard_partition
	exit 0
fi

sfdisk_sdcard

format_sdcard

program_sdcard

exit 0
