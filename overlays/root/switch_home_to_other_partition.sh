#!/usr/bin/env bash
# Use this script to change the mount location of /home
# Optionally transfer the current /home to the new location via rsync
# Parameters:
# 	new partition to use as home, e.g. /dev/mmp...19

# #############################################################################
# Only run as root

if [[ $USER != "root" ]]; then
   	echo "Run script as root";
   	exit
else
	echo "Check ok: script run as root"
fi
# #############################################################################
echo "You should stop any graphical environment to prevent any problems with writes during the switch!"
echo "PRESS ENTER to proceed, or CTRL-C to abort"
read

# #############################################################################

if [[ $# -ne 1 ]]; then
	echo "Need one argument: the partition to use for /home"
	exit
else
	echo "Check ok: Need one argument (target partition)"
fi

# #############################################################################
# Check that target partition exists (as a file)

new_partition=$1
echo "Trying Mounting /home to ${new_partition}"

if [[ ! $new_partition == /dev/mmcblk0p* ]]
then
	echo "Target partition must start with /dev/mmcblk0p"
	exit
else
	echo "Check ok: Target partition must start with /dev/mmcblk0p"
fi

if [[ ! -e "${new_partition}" ]]
then
	echo "Partition file '${new_partition}' does not exist. Make sure to provide the full path"
	exit
else
	echo "Check ok: Target partition exists"
fi

# #############################################################################
# we do not want the target partition to be mounted (yet)
is_mounted=`mount | grep "${new_partition}" | wc --lines`
if [[ ${is_mounted} -gt 0 ]]; then
	echo "The target partition is already mounted. Please umount it before proceeding"
	exit
else
	echo "Check ok: Target partition is not mounted"
fi

already_in_fstab=`cat /etc/fstab | grep ${new_partition} | wc --lines`
if [[ ${already_in_fstab} -gt 0 ]]; then
	echo "The target partition is already defined in /etc/fstab. For now we do not support it"
	exit
else
	echo "Check ok: Target partition is not already present in /etc/fstab"
fi

# #############################################################################
# Transfer data using rsync?
echo "Do you want to transfer the content of the current /home to the new partition? (Y/N)"
read answer
echo "The answer was: ${answer}"

confirmation=''
if [[ "${answer}" == "Y" ]]
then
	echo "You selected: Y. Are you sure? This could overwrite data on ${new_partition}."
 	read confirmation
 	if [[ "${answer}" == "Y" ]]
	then
  		echo "Ok, will commence with transferring data using rsync"
		tmp_mount_point="/tmp_mount/"
		if [[ -d ${tmp_mount_point} ]]
		then
			echo "We need to use a temporary mount point, for reasons of simplicity this is ${tmp_mount_point}"
			echo "This directory exists. Please remove it and start again"
			exit
		else
			echo "Check ok: Temporary mount point ${tmp_mount_point} does not exist"
		fi

		# check for the rsync binary
		test_rsync=`which rsync`
		if [[ -z $test_rsync ]]
		then
			echo "We need rsync to transfer the files. Please install and restart"
			exit
		else
			echo "Check ok: rsync binary found"
		fi

		# now mount the new partition and transfer the files
		mkdir "${tmp_mount_point}"
		mount "${new_partition}" "${tmp_mount_point}"
		echo "Transferring files from /home to ${tmp_mount_point}"
		# transfer the files
		rsync -avh /home/ "${tmp_mount_point}"/
		# cp -r /home/* "${tmp_mount_point}/"
		echo "Finished transferring"
		umount "${tmp_mount_point}"
		test -d "${tmp_mount_point}" && rm -r "${tmp_mount_point}"
  	else
  		echo "Will NOT transfer any data. exiting"
  		exit
  	fi
fi
# #############################################################################
# ok, now we are reasonable safe to proceed
#

fstab_line="${new_partition} /home              ext4   defaults"
echo "Adding line to /etc/fstab"
echo "${fstab_line}"
echo "${fstab_line}" >> /etc/fstab

echo "Reloading systemctl with systemctl daemon-reload"
systemctl daemon-reload

echo "Mounting /home"
mount /home

echo "If you did not get any errors you should be fine now. Better restart to make sure no processes are still accessing the old /home location"
