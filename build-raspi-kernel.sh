#!/bin/sh

#####################################
# Kernel source: git clone --depth=1 https://github.com/raspberrypi/linux raspi-kernel
#Change to path of kernel source: cd raspi-kernel
# Build tools: git clone https://github.com/raspberrypi/tools buildtools
#####################################

p=${0%/*}
c=${0%%/*}
if [ "x${c}" = "x" ]
then 
	lpath=${p}
else
	lpath="${PWD}${p#\.}"
fi
export PATH=$PATH:$lpath/buildtools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin

bootfs=/media/darkise/boot
rootfs=/media/darkise/rootfs
platform="pi3"
KERNEL=kernel7

usage()
{
        echo "Usage: $0 [ARGS]"
        echo
        echo "Options:"
	echo "  -p         platform [pi1, piz, pizw, cm, pi2, pi3, pi3p, pi4]"
        echo "  -r         rootfs"
        echo "  -t         bootfs"
        echo "  -b         build"
        echo "  -i         Install all"
        echo "  -m         Install modules"
        echo "  -k         Install kernel"
        echo "  -h         show this help message and exit"
        exit 1
}

parse_args()
{
        [ -z "$1" ] && usage;
	
	while getopts ":r:t:p:bimkh" option;
	do
	case $option in
	r )
		rootfs=$OPTARG
		;;
	t )
		bootfs=$OPTARG
		;;
	p )
		platform=$OPTARG
		;;
	b )
		BUILD=true
		;;
	m )
		INSTALL_MODULES=true
		;;
	k )
		INSTALL_KERNEL=true
		;;
	i )
		INSTALL_MODULES=true
		INSTALL_KERNEL=true
		;;
	h )
		usage
		;;
	* )
		usage
		;;
	esac
	done
}


build_pi1() {
# For Pi 1, Pi Zero, Pi Zero W, or Compute Module:
	KERNEL=kernel
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcmrpi_defconfig
}

# For Pi 2, Pi 3, Pi 3+, or Compute Module 3:
build_pi3() 
{
	KERNEL=kernel7
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
}

# For Raspberry Pi 4:
build_pi4() 
{
	KERNEL=kernel7l
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2711_defconfig
}

# Modules
build_modules() 
{
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
}

# install the modules:
install_modules() 
{
	sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$rootfs modules_install
}

# Install kernel
install_kernel() 
{
        
	sudo cp $bootfs/$KERNEL.img $bootfs/$KERNEL-backup.img
	sudo cp arch/arm/boot/zImage $bootfs/$KERNEL.img
	sudo cp arch/arm/boot/dts/*.dtb $bootfs/
	sudo cp arch/arm/boot/dts/overlays/*.dtb* $bootfs/overlays/
	sudo cp arch/arm/boot/dts/overlays/README $bootfs/overlays/
}

parse_args $@

case $platfrom in
pi1 )      build_pi1 ;;
piz )      build_pi1 ;;
pizw )     build_pi1 ;;
pi2 )      build_pi3 ;;
pi3 )      build_pi3 ;;
pi3p )     build_pi3 ;;
cm3 )      build_pi3 ;;
pi4)       build_pi4 ;;
esac

[ "$BUILD"    = true ] && build_modules
[ "$INSTALL_MODULES"    = true ] && install_modules
[ "$INSTALL_KERNEL"    = true ] && install_kernel
