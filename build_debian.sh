#!/bin/bash

#####
# Copyright (c) 2016 Sigma Connectivity AB
# Author: Christian Andersson, christian.andersson@sigmaconnectivity.se
# License terms: The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
# Setup Debian on NXP IMX7SABRE
# Author: Christian Andersson, christian.andersson@sigmaconnectivity.se
#
# Purpose:
#   - This script will assist you to make u-boot, kernel and driver for IMX7SABRE board
#
# References:
#   - "L4.1.15_1.2.0_GA BSP release supports the i.MX7D SABRE board.
#   --- http://www.nxp.com/products/microcontrollers-and-processors/arm-processors/i.mx-applications-processors/i.mx-software-and-tools:IMXSW_HOME
#
# This was tested on:
#   - Ubuntu 16.04, x86_64
#   - Ubuntu 14.04, x86_64
#
#####

# Color definitions for colorized output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Used in order to overwrite the first characters on the line with install status prefix eg. '[ OK ]' or '[ ERROR ]'
LAST_PRINTF=""

# Used for setting the installation directory
INSTALL_DIRECTORY="/home/$(whoami)/debian_for_imx7sabre/"
TEMP_WORKING_DIRECTORY=""

# The filename of the logfile
INSTALL_LOG="/tmp/log_$(basename $0)_$(date +%Y-%m-%d_-_%H_%M_%S).txt"

# The default u-boot version to be used
UBOOT_ARCHIVE_URL="http://git.freescale.com/git/cgit.cgi/imx/uboot-imx.git/snapshot/uboot-imx-rel_imx_4.1.15_2.0.0_ga.tar.gz"
UBOOT_ARCHIVE_BASE_NAME=${UBOOT_ARCHIVE_URL##*/}
UBOOT_GIT_COMMIT_URL="http://git.freescale.com/git/cgit.cgi/imx/uboot-imx.git/commit/?h=imx_v2015.04_4.1.15_1.0.0_ga&id=0ec2a019117bb2d59b9672a145b4684313d92782"

GCC_ARCHIVE_URL="https://releases.linaro.org/archive/14.09/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.xz"
GCC_ARCHIVE_BASE_NAME=${GCC_ARCHIVE_URL##*/}

# The default u-boot version to be used
LINUX_IMX_ARCHIVE_URL="http://git.freescale.com/git/cgit.cgi/imx/linux-2.6-imx.git/snapshot/linux-2.6-imx-rel_imx_4.1.15_1.2.0_ga.tar.gz"
LINUX_IMX_ARCHIVE_BASE_NAME=${LINUX_IMX_ARCHIVE_URL##*/}
LINUX_IMX_GIT_COMMIT_URL="http://git.freescale.com/git/cgit.cgi/imx/linux-2.6-imx.git/commit/?h=imx_4.1.15_1.0.0_ga&id=77f61547834c4f127b44b13e43c59133a35880dc"

#If MAKE_MENUCONFIG is empty make menuconfig will not be executed
#MAKE_MENUCONFIG="yes"
MAKE_MENUCONFIG=""

# Fail the command prior to a pipe
set -o pipefail

# Prefix the last printed row with a [ OK ] print
function func_print_ok
{
     printf "\r[ ${GREEN}OK${NC} ] ${LAST_PRINTF}\n" 2>&1 | tee -a $INSTALL_LOG
}

# Print [ ERROR ], error code and the path to the log
function func_print_error_and_exit()
{
     printf "\r[ ${RED}ERROR${NC} ] ${LAST_PRINTF}\n" 2>&1 | tee -a $INSTALL_LOG
     printf "ERROR $1 - Please check \'${INSTALL_LOG}\' for details\n"
     exit $1
}

# Store the input message and print it
function func_print_status_message()
{
     LAST_PRINTF=$1
     printf "${LAST_PRINTF}" 2>&1 | tee -a $INSTALL_LOG
}

# Read the target directory from command line
function func_read_target_dir()
{
     # Ask the user for the target directory to install to
     printf "\nPlease enter the directory to install to (default: ${INSTALL_DIRECTORY}): " 2>&1 | tee -a $INSTALL_LOG
     read TEMP_WORKING_DIRECTORY

     # Set the target directory based on the user input
     if [ -z ${TEMP_WORKING_DIRECTORY} ]; then
           printf "Installing to the default directory: ${INSTALL_DIRECTORY}\n" 2>&1 | tee -a $INSTALL_LOG
     else
           INSTALL_DIRECTORY=${TEMP_WORKING_DIRECTORY}
           printf "Installing to the following directory: ${INSTALL_DIRECTORY}\n" 2>&1 | tee -a $INSTALL_LOG
     fi
}

printf "Setting up and building uBoot, kernel and drivers for the NXP IMX7SABRE board\n"
printf "Saving logfile to: ${INSTALL_LOG}\n\n"

########################## Setup the target directory
func_print_status_message "Setting up target directory" \
     && func_read_target_dir \
     && mkdir -pv ${INSTALL_DIRECTORY} 2>&1 | tee -a $INSTALL_LOG \
     && mkdir -pv ${INSTALL_DIRECTORY}/downloads 2>&1 | tee -a $INSTALL_LOG \
     && sudo cp -v asound.state ${INSTALL_DIRECTORY}/downloads/ 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 1


######################### Fetch and extract gcc
func_print_status_message "Fetching gcc" \
     && cd ${INSTALL_DIRECTORY}/downloads \
     && wget -c ${GCC_ARCHIVE_URL} 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 2

func_print_status_message "Extracting gcc" \
     && mkdir -pv ${INSTALL_DIRECTORY}/toolchain/gcc 2>&1 | tee -a $INSTALL_LOG \
     && tar xvf ${GCC_ARCHIVE_BASE_NAME} -C ${INSTALL_DIRECTORY}/toolchain/gcc/ 2>&1 | tee -a $INSTALL_LOG \
     && GCC_EXTRACT_DIRECTORY=${INSTALL_DIRECTORY}/toolchain/gcc/`ls ${INSTALL_DIRECTORY}/toolchain/gcc/` \
     && func_print_ok \
     || func_print_error_and_exit 3



########################## Fetch and extract u-boot for NXP IMX7SABRE
func_print_status_message "Fetching u-boot for NXP IMX7SABRE archive" \
     && cd ${INSTALL_DIRECTORY}/downloads \
     && wget -c ${UBOOT_ARCHIVE_URL} 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 4



func_print_status_message "Extracting u-boot for NXP IMX7SABRE archive" \
     && mkdir -pv ${INSTALL_DIRECTORY}/source_code/uboot 2>&1 | tee -a $INSTALL_LOG \
     && tar zxvf ${UBOOT_ARCHIVE_BASE_NAME} -C ${INSTALL_DIRECTORY}/source_code/uboot/ 2>&1 | tee -a $INSTALL_LOG \
     && UBOOT_EXTRACT_DIRECTORY=${INSTALL_DIRECTORY}/source_code/uboot/`ls ${INSTALL_DIRECTORY}/source_code/uboot/` \
     && func_print_ok \
     || func_print_error_and_exit 5



########################## Fetch and extract the Linux Kernel
func_print_status_message "Fetching the Linux kernel archive" \
     && mkdir -pv ${INSTALL_DIRECTORY}/downloads 2>&1 | tee -a $INSTALL_LOG \
     && cd ${INSTALL_DIRECTORY}/downloads \
     && wget -c ${LINUX_IMX_ARCHIVE_URL} 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 6



func_print_status_message "Extracting the Linux kernel archive" \
     && mkdir -pv ${INSTALL_DIRECTORY}/source_code/linux_imx 2>&1 | tee -a $INSTALL_LOG \
     && tar zxvf ${LINUX_IMX_ARCHIVE_BASE_NAME} -C ${INSTALL_DIRECTORY}/source_code/linux_imx/ 2>&1 | tee -a $INSTALL_LOG \
     && LINUX_IMX_EXTRACT_DIRECTORY=${INSTALL_DIRECTORY}/source_code/linux_imx/`ls ${INSTALL_DIRECTORY}/source_code/linux_imx/` \
     && func_print_ok \
     || func_print_error_and_exit 7



########################## Setting up environment variables
func_print_status_message "Setting up environment variables needed when compiling" \
     && mkdir -pv ${INSTALL_DIRECTORY}/output/uboot/ 2>&1 | tee -a $INSTALL_LOG \
     && mkdir -pv ${INSTALL_DIRECTORY}/output/kernel/ 2>&1 | tee -a $INSTALL_LOG \
     && export ARCH=arm \
     && export KBUILD_OUTPUT=${INSTALL_DIRECTORY}/output/uboot/ \
     && export CROSS_COMPILE=${GCC_EXTRACT_DIRECTORY}/bin/arm-linux-gnueabihf- \
     && export KERNEL_OUTPUT_DIR=${INSTALL_DIRECTORY}/output/kernel/ \
     && printf "\nARCH=${ARCH}\nKBUILD_OUTPUT=${KBUILD_OUTPUT}\nCROSS_COMPILE=${CROSS_COMPILE}\nKERNEL_OUTPUT_DIR=${KERNEL_OUTPUT_DIR}\n" 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 8



########################## Compile u-boot
func_print_status_message "Compiling u-boot for NXP IMX7SABRE" \
     && cd ${UBOOT_EXTRACT_DIRECTORY} \
     && make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mx7dsabresd_defconfig 2>&1 | tee -a $INSTALL_LOG \
     && make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 9



########################## Compile the Linux kernel
func_print_status_message "Compiling the Linux kernel" \
     && cd ${LINUX_IMX_EXTRACT_DIRECTORY} \
     && printf "\nWorking directory: `pwd`\n" \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper 2>&1 | tee -a $INSTALL_LOG \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE imx_v7_defconfig 2>&1 | tee -a $INSTALL_LOG \
     && if [ -z ${MAKE_MENUCONFIG} ] ; then echo "MAKE_MENUCONFIG variable is not set, will not run make menuconfig" ; else make O=$KERNEL_OUT ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE menuconfig ; fi \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j4 uImage UIMAGE_LOADADDR=0x10008000 2>&1 | tee -a $INSTALL_LOG \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs 2>&1 | tee -a $INSTALL_LOG \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=output modules 2>&1 | tee -a $INSTALL_LOG \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_PATH=output modules_install 2>&1 | tee -a $INSTALL_LOG \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE firmware_install INSTALL_FW_PATH=output/firmware 2>&1 | tee -a $INSTALL_LOG \
     && make O=$KERNEL_OUTPUT_DIR ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE headers_install INSTALL_HDR_PATH=output/headers 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 10



########################## Setup the Debian/Linux base system
func_print_status_message "Setting up the Debian/Linux base system" \
     && mkdir -pv ${INSTALL_DIRECTORY}/output/debian_fs/wheezy 2>&1 | tee -a $INSTALL_LOG \
     && cd ${INSTALL_DIRECTORY}/output/debian_fs/wheezy \
     && sudo apt-get install debootstrap qemu-user-static --assume-yes 2>&1 | tee -a $INSTALL_LOG \
     && sudo debootstrap --foreign --arch=armhf wheezy ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/ ftp://ftp.debian.org/debian/ 2>&1 | tee -a $INSTALL_LOG \
     && sudo cp -v /usr/bin/qemu-arm-static ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/usr/bin/ 2>&1 | tee -a $INSTALL_LOG \
     && sudo chroot ${INSTALL_DIRECTORY}/output/debian_fs/wheezy /debootstrap/debootstrap --second-stage 2>&1 | tee -a $INSTALL_LOG \
     && sudo chroot ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/ sh -c "echo 'root:root' | chpasswd" \
     && sudo chroot ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/ sh -c "echo 'auto eth0\niface eth0 inet dhcp' >> /etc/network/interfaces" \
     && func_print_ok \
     || func_print_error_and_exit 11



########################## Copy kernel modules to the Debian/Linux base system
func_print_status_message "Copy kernel modules to the Debian/Linux base system" \
     && sudo mkdir -pv ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/lib/modules 2>&1 | tee -a $INSTALL_LOG \
     && sudo cp -rv ${INSTALL_DIRECTORY}/output/kernel/output/lib/modules/`ls ${INSTALL_DIRECTORY}/output/kernel/output/lib/modules/`/* ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/lib/modules 2>&1 | tee -a $INSTALL_LOG \
     && sudo cp -rv ${INSTALL_DIRECTORY}/output/kernel/output/headers/include/ ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/usr/ 2>&1 | tee -a $INSTALL_LOG \
     && sudo mkdir -pv ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/lib/firmware \
     && sudo cp -arv ${INSTALL_DIRECTORY}/output/kernel/output/firmware/imx ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/lib/firmware 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 12



########################## Copy ALSA audio settings to the Debian/Linux file system
func_print_status_message "Copy ALSA audio settings to the Debian/Linux file system" \
     && sudo mkdir -pv ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/var/lib/alsa  2>&1 | tee -a $INSTALL_LOG \
     && sudo cp -v ${INSTALL_DIRECTORY}/downloads/asound.state ${INSTALL_DIRECTORY}/output/debian_fs/wheezy/var/lib/alsa/ 2>&1 | tee -a $INSTALL_LOG \
     && func_print_ok \
     || func_print_error_and_exit 12


printf "ALL OK.\n\n" 2>&1 | tee -a $INSTALL_LOG

printf "${YELLOW}Paths to important files:${NC}\n" 2>&1 | tee -a $INSTALL_LOG
printf "${YELLOW}Path to the boot-loader (u-boot.imx):${NC} \"${INSTALL_DIRECTORY}/output/uboot/u-boot.imx\"\n" 2>&1 | tee -a $INSTALL_LOG
printf "${YELLOW}Path to the Device Tree Blob (imx7d-sdb.dtb):${NC} \"${INSTALL_DIRECTORY}/output/kernel/arch/arm/boot/dts/imx7d-sdb.dtb\"\n" 2>&1 | tee -a $INSTALL_LOG
printf "${YELLOW}Path to Linux kernel image (zImage):${NC} \"${INSTALL_DIRECTORY}/output/kernel/arch/arm/boot/zImage\"\n" 2>&1 | tee -a $INSTALL_LOG
printf "${YELLOW}Path to the Debian/Linux root file system:${NC} \"${INSTALL_DIRECTORY}/output/debian_fs/wheezy/\"\n" 2>&1 | tee -a $INSTALL_LOG

printf "\nPlease follow the instructions in the README describing how to flash the image to a SD Card and boot Debian/Linux on the IMX7SABRE board'\n\n" 2>&1 | tee -a $INSTALL_LOG
exit 0

