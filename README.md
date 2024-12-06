Perle build with VyOS
===================

# About this repository

This is the top level repository that contains links to repositories with VyOS
specific packages (organized as Git submodules) and scripts and data that are
used for building those packages and the installation image.

# Repository Structure

There are several directories with their own purpose:

 * `docker/`     Docker build environments
 * `patches/`    Patch files to update scripts and packages

        fs/           Customized file system changes for Perle Systems
        linux-kernel/ Customized Linux-Kernel changes for Perle Systems
        ti_bdebstrap/ Customized patch files to build "ti_bdedstrap" for Perle Systems
        vyos-build/   Customized Patch files to build "VyOS" for Perle Systems

# Clone the repo
To clone the repo
```
git clone https://github.com/jkim71/perle-vyos.git
```

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

After run the docker container, run below command to build whole systems
```
./perle-vyos-image.sh
```
After it builds successfully, run below command from outside of the docker container to build TI BSP package
```
./ti-bsp-image.sh
```
Then it will create final images (Boot and Rootfs) at "vyos-build/ti-bdebstrap/build/"

To flash it to a SD card, connect a SD card and run below command
```
./flash-sdcard.sh
```
