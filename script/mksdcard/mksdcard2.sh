#!/bin/sh

# set verbose to "1" to print 
VERBOSE=0

# ================================================================== #
#     Configure if the SW images are kept in different directories
# ================================================================== #
# no padding uboot
UBOOT=./u-boot-no-padding.bin  # modify to tell where is the no padding uboot

# kernel
KERNEL=./uImage # modify to tell where is kernel

# ramdisk
RAMDISKIMG=./uramdisk.img # modify to tell where is ramdisk

# android rootfs
ROOTFSIMG=./system.img # modify to tell where is android rootfs

# recovery image
RECOVERYIMG=./recovery.img # modify to tell where is recovery image

# vfat mininal partition size
MIN_VFAT_SIZE=50 # modify to set the small partition size for the 1st partition format mounted as SD card to Android

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
BOOT_ROM_SIZE=8

SYSTEM_ROM_SIZE=$(wc -c ${ROOTFSIMG}|cut -d' ' -f1)
SYSTEM_ROM_SIZE=$(( ${SYSTEM_ROM_SIZE} / 1024 / 1024 + 2 ))

DATA_SIZE=$(( ${SYSTEM_ROM_SIZE} * 2 ))

CACHE_SIZE=$(( ${SYSTEM_ROM_SIZE} ))

RECOVERY_ROM_SIZE=$(wc -c ${RECOVERYIMG}|cut -d' ' -f1)
RECOVERY_ROM_SIZE=$(( ${RECOVERY_ROM_SIZE} / 1024 / 1024 + 2 ))
	
if [ "${VERBOSE}" -eq "1" ];then
cat << EOF
SYSTEM : ${SYSTEM_ROM_SIZE}MB
RECO   : ${RECOVERY_ROM_SIZE}MB
DATA   : ${DATA_SIZE}MB
CACHE  : ${CACHE_SIZE}MB
EOF
fi

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
local ROM_SIZE=`expr ${BOOT_ROM_SIZE} + ${SYSTEM_ROM_SIZE} + ${DATA_SIZE}`
ROM_SIZE=`expr ${ROM_SIZE} + ${CACHE_SIZE} + ${RECOVERY_ROM_SIZE}`
BVFAT_SIZE=`expr ${TOTAL_SIZE} - ${ROM_SIZE} - 20 `
VFAT_SIZE=`expr ${TOTAL_SIZE} - ${ROM_SIZE} - 20 - 20 `
EXTEND_SIZE=`expr ${DATA_SIZE} + ${CACHE_SIZE} + 8`

if [ "${VFAT_SIZE}" -lt "${MIN_VFAT_SIZE}" ];then 
	echo "ERROR: Use large size SD card ............."
        print_sdcard_partition
        exit 1
fi
 
if [ "${VERBOSE}" -eq "1" ];then
cat << EOF
TOTAL_SIZE : ${TOTAL_SIZE}MB
ROM_SIZE   : ${ROM_SIZE}MB
BVFAT_SIZE : ${BVFAT_SIZE}MB
VFAT_SIZE  : ${VFAT_SIZE}MB
EXTEND_SIZE: ${EXTEND_SIZE}MB
EOF
fi

}
# ================================================================== #
print_sdcard_partition() {
cat << EOF
TOTAL_SIZE          : ${TOTAL_SIZE}MB
   ROM_SIZE         : ${BOOT_ROM_SIZE}MB
[1]VFAT_SIZE        : ${VFAT_SIZE}MB
[2]SYSTEM_ROM_SIZE  : ${SYSTEM_ROM_SIZE}MB
[3]EXTEND_SIZE      : ${EXTEND_SIZE}MB
[4]RECOVERY_ROM_SIZE: ${RECOVERY_ROM_SIZE}MB
[5]DATA_SIZE        : ${DATA_SIZE}MB
[6]CACHE_SIZE       : ${CACHE_SIZE}MB
EOF
}
# ================================================================== #
sfdisk_sdcard() {
# destroy the partition table
dd if=/dev/zero of=${NODE} bs=1024 count=1

umount_partitions

sfdisk --force -uM ${NODE} << EOF
,${BVFAT_SIZE},b
,${SYSTEM_ROM_SIZE},83
,${EXTEND_SIZE},5
,${RECOVERY_ROM_SIZE},83
,${DATA_SIZE},83
,${CACHE_SIZE},83
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
mkfs.ext4 ${NODE}${PART}2
mkfs.ext4 ${NODE}${PART}4
mkfs.ext4 ${NODE}${PART}5
mkfs.ext4 ${NODE}${PART}6

}
# ================================================================== #
program_sdcard() {
echo "copy uboot..."
dd if=${UBOOT} of=${NODE} bs=1K seek=1 && sync && sync
echo "copy linux kernel..."
dd if=${KERNEL} of=${NODE} bs=1M seek=1 && sync && sync
echo "copy ramdisk..."
dd if=${RAMDISKIMG} of=${NODE} bs=6M seek=1 && sync && sync
echo "copy android rootfs..."
dd if=${ROOTFSIMG} of=${NODE}${PART}2  && sync && sync
echo "copy recovery image..."
dd if=${RECOVERYIMG} of=${NODE}${PART}4  && sync && sync
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
