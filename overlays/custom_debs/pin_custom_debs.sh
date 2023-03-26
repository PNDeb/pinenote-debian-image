#!/usr/bin/env bash
# hold/pin custom-installed packages
set -eux -o pipefail

for package_group_name in "mutter" "mesa"; do
    packages_found=false
    regex="$package_group_name\/([^_]+)"
    for file in /root/custom_debs/$package_group_name/*.deb ; do
        if [[ $file =~ $regex ]]; then
            apt-mark hold "${BASH_REMATCH[1]}"
            packages_found=true
        fi
    done

    if [ ! "$packages_found" ] ; then
        echo "Expected to find debian packages for $package_group_name, but failed"
        exit 1
    fi
done

apt-mark hold xournalpp
