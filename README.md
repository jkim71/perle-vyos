Perle build with VyOS toplevel build
===================

# About this repository

This is the top level repository that contains links to repositories with VyOS
specific packages (organized as Git submodules) and scripts and data that are
used for building those packages and the installation image.

# Repository Structure

There are several directories with their own purpose:

 * `patches/`    Patch files to update scripts and packages
 *      `configs/`      Linux configurations for Perle Systems
 *      `fs/`           Customize setting for Perle Systems
 *      `ti_bdebstrap/` Customized patch files to build "ti_bdestrap" for Perle Systems
 *      `vyos-build/`   Customized Patch files to build "VyOS" for Perle Systems

# Building

This is designed to build in a Dockr container.

To install a docker, see [Install Docker Engine on Debian](https://docs.docker.com/engine/install/debian/).

To build a docker image
```
docker build -t vyos/vyos-build:current-arm64 docker --build-arg ARCH=arm64v8/ --platform linux/arm64/v8 --no-cache
```

To run the docker image
```
docker run --rm -it --privileged -v ~/.gitconfig:/etc/gitconfig -v $(pwd):/vyos -w /vyos vyos/vyos-build:current-arm64 bash
```

After you can run the docker, run below command to build whole systems
```
./build-perle-yos.sh
```
