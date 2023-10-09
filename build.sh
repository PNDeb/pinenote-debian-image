#!/bin/sh

# This "build system" assumes that the recipes are part of a build "pipeline":
# each recipe in the pipeline continues the work done by the previous recipe.
# That work is saved in a tar.gz file with the same name as the recipe that
# build it. This method allows us to agressively cache the work done at each
# step, and only rebuild the tar.gz files starting with the first recipe that
# was changed in the pipeline.
# ./build.sh builds by default the recipes found in the recipes-pipeline file.
# You can give it another pipeline with the -r option.

# Tests if we already have a built .tar.gz for the current recipe and that can
# be used (has not become obsolete).
# Be warned: tests are not exhaustive. For example, if you have changed the
# overlays or scripts directories you must manually remove the obsolete tar.gz
# files or else this dumb script will wrongly reuse them!
needs_build() {
	local yes=0 no=1
	local current=$1
	local previous=$2
	local targz="${current%.yaml}.tar.gz"
	if [ ! -f "$targz" ];           then return $yes; fi
	if [ "$current" -nt "$targz" ]; then return $yes; fi

	if [ ! -z "$previous" ]; then
		local prev_targz="${previous%.yaml}.tar.gz"
		if [ ! -f "$prev_targz" ]; then
			echo Error: Previous tar archive not found! Aborting.
			exit 31
		fi
		if [ "$prev_targz" -nt "$targz" ]; then return $yes; fi
	fi
	# maybe TODO: check which overlays and scripts this recipe is using and
	# check also if those files are newer

	echo "Already have good(maybe?)"  "$targz"
	return $no
}

# Calls debos to build recipe $1. Previous recipe in the pipeline is given as
# parameter $2 to the function.  It also sets the template-vars -t targz and -t
# prevtargz that are used by the recipe $1.
build() {
	local tars=" -t targz:${1%.yaml}.tar.gz "
	if [ ! -z "$2" ]; then
		tars="$tars -t prevtargz:${2%.yaml}.tar.gz "
	fi
	$DEBOS_CMD $ARGS $tars "$1" || exit 34
}

# The default values (see *.yaml) are in each comment above the variable
# 'pinenote'
hostname=
# 'arm64'
arch=
# 'user'
username=
# '1234'
password=
# 'bookworm'
debian_suite=
recipes_pipeline=recipes-pipeline

# '900MB' - enough to extract the last tar.gz; resize fs at runtime
image_size=

# ARGS="-m 8G -v --show-boot"
ARGS="-m 8G -v "

read_options() {
	while getopts "x:H:p:u:r:s:" opt
	do
	  case "$opt" in
	    H ) hostname="$OPTARG" ;;
	    u ) username="$OPTARG" ;;
	    p ) password="$OPTARG" ;;
	    x ) debian_suite="$OPTARG" ;;
	    r ) recipes_pipeline="$OPTARG" ;;
	    s ) image_size="$OPTARG" ;;
	  esac
	done

	[ "$hostname" ] && ARGS="$ARGS -t hostname:$hostname"
	[ "$username" ] && ARGS="$ARGS -t username:$username"
	[ "$password" ] && ARGS="$ARGS -t password:$password"
	[ "$debian_suite" ] && ARGS="$ARGS -t debian_suite:$debian_suite"
	[ "$image_size" ] && ARGS="$ARGS -t imagesize:$image_size"

	if [ -f lastbuildoptions ]; then
		last=`tail -n 1 lastbuildoptions`
		if [ "$last" != "$ARGS" ]; then
			echo "WARNING: you are using different options than "
			echo "last time. You might need to delete some previously "
			echo "built .tar.gz files so we don't reuse them with the "
			echo "wrong options!"
			echo "- last time options: \"$last\" "
			echo "- current   options: \"$ARGS\" "
			read -p 'Should I continue building? (y/N) ' answer
			if [ "$answer" != "y" ]; then
				echo "Aborting."
				exit 33
			fi
		fi
	fi
}

# ===== main ===== #

read_options $@

DEBOS_CMD=debos

previous_recipe=

recipes=(`grep -v '#' "$recipes_pipeline" | grep '.*\.yaml'`)
rcounter=0
for recipe in ${recipes[@]}; do
	echo "|-- Procesing $recipe --|"
	if [ ! -f "$recipe" ]; then
		echo Recipe not found. Aborting.
		exit 30
	fi
	if needs_build "$recipe" "$previous_recipe"; then
		echo " needs build "
		build "$recipe" "$previous_recipe"
		echo "Individual files:"
		du -sh *
		echo "complete directory:"
		du -sh .
		df -h
		# delete previous archives to save space
		for to_del in `seq 1 $((rcounter-0))`; do
		   	echo "Deleting: `printf %02i $to_del;`_*.tar.gz;"
			# we want to keep the last tar.gz file, which is generated in step 11
			if [ $to_del -lt 11 ]; then
		   		rm `printf %02i $to_del;`_*.tar.gz;
			fi
	   	done
		echo "Directory size after cleanup: `du -sh .`"
		df -h
	else
		echo " build not needed, skipping."
	fi
	previous_recipe="$recipe"
	rcounter=$((rcounter+1))
done
echo "$ARGS" > lastbuildoptions
echo "|-- build done. --|"

ls

# we build as root, but modify/manage as user
# chown -R mweigand:mweigand .

# rename the final tar.gz file to a standardized name
final_targz="pinenote_arm64_debian_bookworm.tar.gz"
test -e "${final_targz}" && rm "${final_targz}"

last_targz_file=$(ls -1 *.tar.gz | tail -1)
echo "Renaming ${last_targz_file} to ${final_targz}"
mv "${last_targz_file}" "${final_targz}"
