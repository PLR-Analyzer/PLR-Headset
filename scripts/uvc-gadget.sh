#!/bin/sh

set -e

modprobe libcomposite

CONFIG="/sys/kernel/config/usb_gadget/g1"

mkdir -p $CONFIG
cd $CONFIG || exit 1

echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0103 > bcdDevice # v1.0.3
echo 0x0200 > bcdUSB    # USB 2.0

echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol
echo 0x40 > bMaxPacketSize0

mkdir -p strings/0x409
mkdir -p configs/c.1
mkdir -p configs/c.1/strings/0x409

SERIAL=$(cat /sys/firmware/devicetree/base/serial-number)
echo $SERIAL        		> strings/0x409/serialnumber
echo "Marcel Schepelmann"	> strings/0x409/manufacturer
echo "PLR Headset"			> strings/0x409/product
echo "PLR Headset"	 		> configs/c.1/strings/0x409/configuration
echo 500 					> configs/c.1/MaxPower

config_frame() {
	# Example usage:
	# config_frame <width> <height> <format> <name>

	WIDTH=$1
	HEIGHT=$2
	FORMAT=$3
	NAME=$4

	wdir=functions/uvc.usb0/streaming/$FORMAT/$NAME/${HEIGHT}p

	mkdir -p $wdir
	echo $WIDTH > $wdir/wWidth
	echo $HEIGHT > $wdir/wHeight
	echo $(( $WIDTH * $HEIGHT * 2 )) > $wdir/dwMaxVideoFrameBufferSize
	cat <<EOF > $wdir/dwFrameInterval
333333
EOF
}

config_uvc() {
	echo "	Creating UVC gadget functionality : uvc.usb0"
	mkdir functions/uvc.usb0

	config_frame 1280 720 mjpeg m

	mkdir -p functions/uvc.usb0/streaming/header/h
	mkdir -p functions/uvc.usb0/control/header/h
	ln -s functions/uvc.usb0/streaming/mjpeg/m        functions/uvc.usb0/streaming/header/h
	ln -s functions/uvc.usb0/streaming/header/h       functions/uvc.usb0/streaming/class/fs
	ln -s functions/uvc.usb0/streaming/header/h       functions/uvc.usb0/streaming/class/hs
	ln -s functions/uvc.usb0/streaming/header/h       functions/uvc.usb0/streaming/class/ss
	ln -s functions/uvc.usb0/control/header/h         functions/uvc.usb0/control/class/fs
	ln -s functions/uvc.usb0/control/header/h         functions/uvc.usb0/control/class/ss

	echo 1024 > functions/uvc.usb0/streaming_maxpacket

	ln -s functions/uvc.usb0 configs/c.1/uvc.usb0
}

config_usb_serial() {
	mkdir -p functions/acm.usb0
	ln -s functions/acm.usb0 configs/c.1/acm.usb0
}

echo "Configure USB gadget webcam interface"
config_uvc

echo "Configure USB gadget serial interface"
config_usb_serial

ls /sys/class/udc > UDC

udevadm settle -t 5 || :

