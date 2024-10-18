#!/usr/bin/bash

base_dir=$(pwd)
pkgs_dir=scripts/package-build
output_dir=packages

#echo "Base directory: $base_dir"

if [[ $1 == "all" ]]; then
    patt=$pkgs_dir/*/
else
    patt=$1
fi

for dir_name in  $(ls -d $patt); do
    echo "Dir name: $dir_name"
    cd $base_dir/$dir_name
    python3 build.py

    # copy all deb files to the base directory
    if [[ ! -d $base_dir/$output_dir ]]; then
        echo "Making Directory: $base_dir/$output_dir"
        mkdir -p $base_dir/$output_dir
    fi
    cd $base_dir
    cp -rvf $dir_name/*.deb $output_dir | true
done

