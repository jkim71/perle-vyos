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
docker build -t vyos/vyos-build:current-arm64v8 docker --build-arg ARCH=arm64v8/ --platform linux/arm64/v8 --no-cache
```

To run the docker image
```
docker run --rm -it --privileged --sysctl net.ipv6.conf.lo.disable_ipv6=0 \
  -v $(pwd):/vyos -v /dev:/dev -v /etc/fstab:/etc/fstab \
  -v "$HOME/.gitconfig":/etc/gitconfig -w /vyos \
  vyos/vyos-build:current-arm64v8 bash -c "sudo sed -i 's|Defaults\s\+secure_path=\"\(.*\)\"|Defaults secure_path=\"\1:/opt/go/bin\"|' /etc/sudoers && /bin/bash"
```
Currently, it supports 2 platform which are "bookworm-am64xx-evm" and "bookworm-j7200-evm"
To support auto-complete for above platforms, run below command before you build system.
```
source ./autocomp.sh
```

1. On ARM platform (Mac PC which has M series CPU)
To build whole system, run below command
```
./perle-vyos-image.sh <platform>
```
2. On x86 platform(Windows PC. Intel/AMD CPUs)
To build whoile system, run below command
```
./perle-vyos-image.sh <platform>
```
Then, to build TI BSP package, run below command from outside of the docker container
```
./ti-bsp-image.sh <platform>
```

Then it will create final images (Boot and Rootfs) at "vyos-build/ti-bdebstrap/build/"

To flash it to a SD card, connect a SD card and run below command
```
./flash-sdcard.sh <platform>
```
