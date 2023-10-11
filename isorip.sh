#!/bin/bash

# Check dependencies
deps=("printf|fprintd" "setcd|setcd" "sed|sed" "blkid|util-linux" "dd|coreutils" "udisksctl|udisks2")
missingdeps=""
missingdepsinstall="sudo apt install"

for dep in "${deps[@]}"; do
	if ! type $(echo "$dep" | cut -d\| -f1) &> /dev/null; then
		missingdeps=$(echo "$missingdeps$(echo "$dep" | cut -d\| -f1), ")
		missingdepsinstall=$(echo "$missingdepsinstall $(echo "$dep" | cut -d\| -f2)")
	fi
done
if [ -n "$missingdeps" ]; then
	echo "[ERROR] Missing dependencies! ($(echo "$missingdeps" | xargs | sed 's/.$//'))"
	echo "        You can install them using this command:"
	echo "        ----------------------------------------"
	echo "        $missingdepsinstall"
	echo "        ----------------------------------------"
	exit 1
fi


# Defining variables for later use
sourcedrive="$1"
scriptroot="$(dirname $(realpath $0))"
outputdir="$(awk '/^outputdir/' $scriptroot/settings.cfg | cut -d '=' -f2 | cut -f1 -d"#" | xargs)"

# Check if the source drive has actually been set and is available
if [ -z "$sourcedrive" ]; then
	echo "[ERROR] Source Drive is not defined. When calling this script manually, make sure to pass the drive path as a variable: bash isorip.sh [DRIVE]"
	exit 1
fi
setcd -i "$sourcedrive" | grep --quiet 'Disc found'
if [ $? -ne 0 ]; then
        echo "[ERROR] $sourcedrive: Source Drive is not available."
        exit 1
fi

# Construct the arguments for later use
if [[ $outputdir == \~* ]]; then
	if [[ $outputdir == \~/* ]]; then
		outputdir=$(echo "/home/${SUDO_USER:-$USER}/${outputdir:2}" | sed 's:/*$::')
	else
		outputdir="/home/${SUDO_USER:-$USER}"
	fi
fi
if [ ! -d "$outputdir" ]; then
	mkdir -p $outputdir
	if [ ! -d "$outputdir" ]; then
		echo "[ERROR] $sourcedrive: The output directory specified in settings.conf is invalid and couldn't be created!"
		exit 1
	fi
fi

echo "[INFO] $sourcedrive: Gathering disc information"

#Extract DVD Title from Drive
DISKTITLERAW=$(blkid -o value -s LABEL $sourcedrive)
DISKTITLERAW=${DISKTITLERAW// /_}
DISKTITLERAW=${DISKTITLERAW:-disc}
# NOWDATE=$(date +"%Y-%m-%d_%k-%M-%S")
# DISKTITLE=$(echo "${DISKTITLERAW}_-_$NOWDATE")

DISKTITLE=$(echo "${DISKTITLERAW}")

filename_suffix="index"
case "$2" in
    *'date'*)
		filename_suffix="date"
        ;;
    *'index'*)
        filename_suffix="index"
        ;;
    *)
		filename_suffix="index"
        ;;
esac

if [ $filename_suffix = "date" ]; then
	echo "[INFO] Using DATE filename suffix."
	NOWDATE=$(date +"%Y-%m-%d_%k-%M-%S")
	DISKTITLE=$(echo "${DISKTITLERAW}_-_$NOWDATE")
else
	echo "[INFO] Using INDEX filename suffix."
	# CHECK IF FILE EXIST AND RENAME WITH INDEX INCREMENT
	if [[ -e $outputdir/$DISKTITLE.iso || -L $outputdir/$DISKTITLE.iso ]] ; then
		i=0
		while [[ -e $outputdir/$DISKTITLE-$i.iso || -L $outputdir/$DISKTITLE-$i.iso ]] ; do
			let i++
		done
		DISKTITLE=$DISKTITLE-$i
	fi
	touch -- "$outputdir/$DISKTITLE".iso
fi

# Check if disc is mounted and attempt to unmount it eventually
if grep -qs '$sourcedrive ' /proc/mounts; then
	echo "[INFO] $sourcedrive: Attempting to unmount drive."
	udisksctl unmount -b $sourcedrive
	if [ $? -eq 0 ]; then
        echo "[INFO] $sourcedrive: Successfully nmounted drive."
    else
		echo "[WARN] $sourcedrive: Couldn't unmount drive."
		echo "                     Please do not access the drive whilst the ISO is being created."
	fi
fi

# Create ISO
echo "[INFO] $sourcedrive: Started ripping process"
dd if=$sourcedrive of=$outputdir/$DISKTITLE.iso status=none
if [ $? -eq 0 ]; then
	echo "[INFO] $sourcedrive: Ripping finished."
        exit 0
else
	printf "[ERROR] $sourcedrive: Ripping failed.\n          Did you insert a compatible disc? Non-data discs (like audio CDs) ususally won't work.\n"
	exit 1
fi
