#!/usr/bin/bash

base_dir=$(pwd)
pkgs_dir=packages
output_dir=

#echo "Base directory: $base_dir"

if [[ $1 == "all" ]]; then
    patt=$pkgs_dir/*/
else
    patt=$1
fi

for dir_name in  $(ls -d $patt); do
    pkg_name_def=""
    pkg_name=""
    scm_commit=""
    scm_url=""
    build_cmd=""

    # remove all deb files in the directory before compiling deb files
#    find $base_dir/$dir_name -name *.deb | xargs rm
    echo "Dir name: $dir_name"

    cd $base_dir/$dir_name
    if [[ $dir_name =~ "linux-kernel" ]]; then
        file_name=$base_dir/$dir_name/perle-Jenkinsfile
    else
        file_name=$base_dir/$dir_name/Jenkinsfile
    fi

    echo "File name: $file_name"
    while read -r line; do
        if [[ $line =~ "def package_name" ]]; then
            pkg_name_def="$(echo $line | awk -F"= " '{print $2}' | tr -d "'" | tr -d "," | tr -d "[" | tr -d "]" )"
            echo "Defined package name: $pkg_name_def"
        elif [[ $line =~ "'name'" ]]; then
            pkg_name="$(echo $line | awk -F": " '{print $2}' | tr -d "'" | tr -d "," | tr -d "[" | tr -d "]" )"
            if [[ $pkg_name_def != "" ]]; then
                pkg_name=$pkg_name_def
            fi
            echo "Package name: $pkg_name"
        elif [[ $line =~ "'scmCommit'" ]]; then
            scm_commit="$(echo $line | awk -F": " '{print $2}' | tr -d "'" | tr -d "," | tr -d "[" | tr -d "]" )"
            echo "scmCommit: $scm_commit"
        elif [[ $line =~ "'scmUrl'" ]]; then
            scm_url="$(echo $line | awk -F": " '{print $2}' | tr -d "'" | tr -d "," | tr -d "[" | tr -d "]" )"
            echo "scmUrl: $scm_url"
        elif [[ $line =~ "'buildCmd'" ]]; then
            build_cmd="$(echo $line | awk -F": " '{print $2}' | tr -d "'" | tr -d "," | tr -d "[" | tr -d "]" )"
            echo "Buildcmd: $build_cmd"
            if [[ -n $scm_url ]]; then
                if [[ -d $pkg_name ]]; then
                    echo "pkg_name: $pkg_name"
                    cd $pkg_name
                else
                    echo "clone pkg_name: $pkg_name"
                    git clone $scm_url $pkg_name
                    cd $pkg_name
                    git checkout $scm_commit
                fi
            fi
            eval "$build_cmd"
            cd $base_dir/$dir_name
            pkg_name_def=""
            pkg_name=""
            scm_commit=""
            scm_url=""
            build_cmd=""
#        else
#            echo "Undefined line: $line"
        fi
    done < "$file_name"
    cd $base_dir

    # copy all deb files to the base directory
    if [[ ! -d $pkgs_dir/$output_dir ]]; then
        echo "Making Directory: $pkgs_dir/$output_dir"
        mkdir -p $pkgs_dir/$output_dir
    fi
    echo "Copy all deb files from $base_dir/$dir_name to $pkgs_dir/$output_dir ..."
    cp -rf $base_dir/$dir_name/*.deb $pkgs_dir/$output_dir | true
done

