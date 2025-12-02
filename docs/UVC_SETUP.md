# Raspberri Pi Zero 2 W UVC-Gadget

These are the instructions for setting up a Raspberry Pi as a UVC gadget. A slightly modified version of the UVC gadget from [freedesktop.org](https://www.freedesktop.org/wiki/) is used for UVC functionality: https://gitlab.freedesktop.org/camera/uvc-gadget

1. Install Raspberry Pi OS Bookworm (32-bit) Lite with `Raspberry Pi Imager`.
    - Don't forget to enable ssh and set a user with password via the gear icon.
2. Navigate into the bootfs partition.
3. Edit the file called `config.txt` and append `dtoverlay=dwc2`.
4. Edit the `cmdline.txt` file and add `modules-load=dwc2,libcomposite` immediatly after `rootwait`.
5. Now the SD-Card can be removed and inserted into the raspberry pi.
6. Let the raspberry pi boot up and access it via ssh.
7. Now update the system and install the necessary packages:
```bash
sudo apt update && sudo apt upgrade && sudo apt install git meson libcamera-dev libjpeg-dev
```
8. Add a console on ttyAMA0 and enable auto login
```bash
sudo ln -sf /usr/lib/systemd/system/serial-getty@.service /etc/systemd/system/getty.target.wants/serial-getty@ttyGS0.service
sudo sed '/^ExecStart=/ s/-o .-p -- ..u./--skip-login --noclear --noissue --login-options "-f pi"/' -i /usr/lib/systemd/system/serial-getty@.service
```
9. Next, download the UVC gadget software. This helps your Raspberry Pi stream video over USB:
```bash
git clone https://github.com/PLR-Analyzer/PLR-Headset.git
```
10. Navigate to the downloaded folder:
```bash
cd PLR-Headset
```
11. You now need to make, build, and install the software with the following commands:
```bash
make uvc-gadget
cd build
sudo meson install
sudo ldconfig
```
Use the following command to make the script executable:
```bash
cd
sudo chmod +x tbi-uvc-gadget/scripts/uvc-gadget.sh
```

13. After rebooting make the necessary kernel configuration:
```bash
sudo ./tbi-uvc-gadget/scripts/uvc-gadget.sh
```
14. Run the uvc-gadget. The -c flag sets libcamera as a source, arg 0 selects the first available camera on the system. All cameras will be listed, you can re-run with -c n to select camera n or -c ID to select via the camera ID.
```bash
uvc-gadget -c 0 uvc.usb0
```

## Make the changes permanent
If everythink has worked, you can make the changes permanent. To do this copy and and enable the two systemd services in `tbi-uvc-gadget/scripts/uvc-gadget.service`

```bash
sudo cp tbi-uvc-gadget/scripts/uvc-gadget.service /etc/systemd/system/
sudo cp tbi-uvc-gadget/scripts/webcam.service /etc/systemd/system/
sudo systemctl enable uvc-gadget.service
sudo systemctl enable webcam.service 
```

Now the uvc-gadget and serial-gadget will be configured automatically after booting.

## References:
Offical Raspberry Pi Tutorial: https://www.raspberrypi.com/tutorials/plug-and-play-raspberry-pi-usb-webcam/

Tutorial for UVC-Gadget with a Serial Device: http://www.davidhunt.ie/raspberry-pi-zero-with-pi-camera-as-usb-webcam/