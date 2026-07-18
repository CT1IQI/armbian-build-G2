#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4
CPL=0
FRT=0
RTL8125=0
	
saturncm5() {
	CPL=0
	# remove making of user in firstlogin; user 'pi' is defined here
	# set systemd service with the user to auto login
	# make pi user
	# password made via: perl -e 'print crypt("<password>", "password")'
	echo "start customization saturncm5, IQI=${IQI}, FRT=${FRT}"
	# password: saturn
	/usr/sbin/useradd -U -c 'Anan G2' -p 'pajUk/yt3rggA' -d '/home/pi' -G tty,disk,dialout,sudo,audio,video,plugdev,games,users,systemd-journal,input,render,netdev,_ssh,adm,cdrom -m -s '/bin/bash' pi
	echo "user pi with password added to image"
	/usr/sbin/usermod -p 'pajUk/yt3rggA' root
	echo "password set for user root"
	# skip first login 
	# rm /root/.not_logged_in_yet
	# Automatic setting of time zone and locale, without user intervention
	cp  /tmp/overlay/saturncm5/armbian-firstlogin					/usr/lib/armbian/
	chmod 755 														/usr/lib/armbian/armbian-firstlogin
	# set systemd service with the user and app to auto login
	echo "setting services"
	mkdir -p /etc/systemd/system/graphical.target.wants
	mkdir -p /etc/systemd/multi-user.target.wants
	cp  /tmp/overlay/saturncm5/labwc.service						/etc/systemd/system/
	ln -s /etc/systemd/system/labwc.service							/etc/systemd/system/graphical.target.wants/labwc.service
	ln -s /etc/systemd/system/power-button.service					/etc/systemd/system/multi-user.target.wants/power-button.service
	# set power button monitor service
	cp  /tmp/overlay/saturncm5/power-button.service					/etc/systemd/system/
	# create directory with contents for power off scripts
	echo "setting scripts"
	mkdir -p /etc/Saturn
	cp /tmp/overlay/saturncm5/wait_shutdown.py						/etc/Saturn/
	cp /tmp/overlay/saturncm5/shutdown.sh							/etc/Saturn/
	chmod 755 /etc/Saturn/*
	# choose xdma driver
	# cp /tmp/overlay/saturncm5/blacklisted.conf						/etc/modprobe.d/
	# chown root:root													/etc/modprobe.d/blacklisted.conf
	# Frontpanels firmwares
	echo "setting frontpanel firmwares"
	cd /tmp/overlay/saturncm5/SerialUSB
	if [[ $FRT -eq 7 ]]
	then
		cp G2_7inch_serial_USB_115200-4.1.1.ino.uf2					/etc/Saturn/	
	fi
	if [[ $FRT -eq 8 ]]
	then
		cp flash_8inch_front.sh										/etc/Saturn/
		chmod 755													/etc/Saturn/flash_8inch_front.sh
		cp G2_8inch_serial_USB_9600-5.3.10.ino.hex				/etc/Saturn/
		cd /etc/Saturn/
		ln -s G2_8inch_serial_USB_9600-5.3.10.ino.hex			G2_8inch_serial_USB-latest.ino.hex
		# Avrdude
		[ -f /tmp/overlay/saturncm5/avrdude.tar ] && {
			mkdir -p /home/pi/github/
			tar -x -f /tmp/overlay/saturncm5/avrdude.tar -C			/home/pi/github/
			cd /home/pi/github/
			chown -R pi:pi											avrdude
			chmod -R 755											avrdude
			cd /home/pi/github/avrdude/build_linux
			sudo cmake --install .
		}
	fi
	# sudoers so pi can write /etc
	echo "setting sudoers"
	cp -R /tmp/overlay/saturncm5/sudoers*							/etc/
	chown -R root:root												/etc/sudoers*
	# Saturn && Pihpsdr
	[ -d /home/pi/github ] || mkdir -p /home/pi/github
	cd /home/pi/github
	# SATURN fresh 
	[[ $CPL -eq 1 ]] && {
		echo "compiling Saturn"
		git clone --single-branch -b main --depth=1 https://github.com/laurencebarker/Saturn.git
		cd /home/pi/github/Saturn/sw_projects/P2_app			
		make clean && make
		# sw_tools
		# axi_rw
		cd /home/pi/github/Saturn/sw_tools/axi_rw
	    make clean && make
		# flashwriter
		cd /home/pi/github/Saturn/sw_tools/flashwriter
	    make clean && make
	}
	# SATURN canned
	[[ $CPL -eq 0 ]] && {
		echo "installing Saturn from canned image"
		# check whether Saturn repository is available in overlay; if not clone them
		[ -f /tmp/overlay/saturncm5/saturn.tar ]	&&	{
			# work now with prepped Saturn
			tar -x -f /tmp/overlay/saturncm5/saturn.tar -C			/home/pi/github/
			chown -R pi:pi											/home/pi/github/Saturn
		}		
	}
	[ -d /usr/local/bin ] || mkdir -p								/usr/local/bin
	# sw_projects
	# P2_app
	cp /home/pi/github/Saturn/sw_projects/P2_app/p2app				/usr/local/bin/
	chmod 755 /usr/local/bin/p2app
	# audiotest
	cd /home/pi
	chmod 755 github/Saturn/sw_projects/audiotest/audiotest
	# biascheck
	chmod 755 github/Saturn/sw_projects/biascheck/biascheck
	# sw_tools
	# axi_rw
	chmod 755 github/Saturn/sw_tools/axi_rw/axi_rw
	# flashwriter
	chmod 755 github/Saturn/sw_tools/flashwriter/flashwriter
	# PIHPSDR dl1ycf
	echo "installing pihpsdr_dl1ycf"
	[ -f /tmp/overlay/saturncm5/pihpsdr_dl1ycf.tar ] && {
		tar -x -f /tmp/overlay/saturncm5/pihpsdr_dl1ycf.tar -C		/home/pi/github/
		cd /home/pi/github/pihpsdr_dl1ycf
		chmod 755													pihpsdr
		cp pihpsdr								 					/usr/local/bin/pihpsdr_dl1ycf
		ln -s /usr/local/bin/pihpsdr_dl1ycf						/usr/local/bin/pihpsdr
	}
	# PIHPSDR ct1iqi
	[ -f /tmp/overlay/saturncm5/pihpsdr_ct1iqi.tar ] && {
		echo "installing pihpsdr_ct1iqi"
		tar -x -f /tmp/overlay/saturncm5/pihpsdr_ct1iqi.tar -C		/home/pi/github/
		cd /home/pi/github/pihpsdr_ct1iqi
		chmod 755													pihpsdr
		cp pihpsdr													/usr/local/bin/pihpsdr_ct1iqi
		chmod 755 /usr/local/bin/pihpsdr_ct1iqi
	}
	# .config labwc, pulse, pihpsdr, wayvnc, wsjt-x
	echo "configuring labwc"
	if [[ $FRT -eq 0 ]]
	then
		cp -R /tmp/overlay/saturncm5/.config_0inch					/home/pi/.config
		cd /home/pi/.config/labwc
		[ -e autostart ] && rm autostart
		ln -s auto_p2app											autostart
	fi
	if [[ $FRT -eq 7 ]]
	then
		cp -R /tmp/overlay/saturncm5/.config_7inch					/home/pi/.config
		cd /home/pi/.config/labwc
		[ -e autostart ] && rm autostart
		ln -s auto_pihpsdr											autostart
	fi	
	if [[ $FRT -eq 8 ]]
	then
		cp -R /tmp/overlay/saturncm5/.config_8inch				/home/pi/.config
		cd /home/pi/.config/labwc
		[ -e autostart ] && rm autostart
		ln -s auto_pihpsdr										autostart
	fi
	chmod 755														/home/pi/.config/labwc/lwc.sh
	chmod 755														/home/pi/.config/labwc/kbdt.sh
	chmod 755														/home/pi/.config/pihpsdr/pihpsdr_firstrun.sh
	touch /home/pi/.config/pihpsdr/.firstrun
	cp /tmp/overlay/saturncm5/.profile_us						/home/pi/.profile
	cp -R /tmp/overlay/saturncm5/.local_us						/home/pi/.local
	chown -R pi:pi													/home/pi
	# add fonts with stroke in zero
	cp -R /tmp/overlay/saturncm5/fonts/truetype/allerta-regular		/usr/share/fonts/truetype/
	cp -R /tmp/overlay/saturncm5/fonts/truetype/robotomono			/usr/share/fonts/truetype/
	cp -R /tmp/overlay/saturncm5/fonts/truetype/inconsolata-2		/usr/share/fonts/truetype/
	cp -R /tmp/overlay/saturncm5/fonts/truetype/brunoace			/usr/share/fonts/truetype/
	cp -R /tmp/overlay/saturncm5/fonts/truetype/nevermind-display	/usr/share/fonts/truetype/
	#	panfrost firmware
	mkdir -p /lib/firmware/arm/mali/arch10.8
	cp /tmp/overlay/saturncm5/mali_csffw.bin						/lib/firmware/arm/mali/arch10.8/
	mkdir -p /var/data/src
	cd /var/data/src 
	chown -R pi:pi													/var/data
	# backlight regulation
	[[ $FRT -eq 7 ]] || [[ $FRT -eq 8 ]] && {
		cp /tmp/overlay/saturncm5/backlight.sh						/usr/local/bin/
		chmod 755													/usr/local/bin/backlight.sh
	}
	# wvkbd virtual keyboard
	[ -f /tmp/overlay/saturncm5/wvkbd-g2.tar ] && {
		tar -x -f /tmp/overlay/saturncm5/wvkbd-g2.tar -C			/var/data/src
		cd /var/data/src/wvkbd
		chmod 755													wvkbd-g2
		cp wvkbd-g2								 					/usr/local/bin/
    }	
	#	libdrm
	cd /var/data/src
	[ -d /var/data/src/drm ] && rm -Rf /var/data/src/drm
	if [[ $CPL -eq 1 ]]
	then
		echo "compiling drm"
		git clone -b main --single-branch --depth=1 https://gitlab.freedesktop.org/mesa/drm
		cd drm/
		mkdir build
		cd build/
		meson setup
		meson install
	else
		echo "installing drm from canned image"
		[ -e /tmp/overlay/saturncm5/drm.tar ] &&  {
			tar -x -f /tmp/overlay/saturncm5/drm.tar -C					/var/data/src
		}
		cd drm/build
		meson install --no-rebuild
	fi
	#	mesa
	cd /var/data/src
	if [[ $CPL -eq 1 ]]
	then
		echo "compiling mesa"
		[ -d /var/data/src/mesa ] && rm -Rf /var/data/src/mesa
		git clone -b main --single-branch --depth=1 https://gitlab.freedesktop.org/mesa/mesa.git
		cd mesa
		mkdir build
		cd build
		meson setup -Dvulkan-drivers= -Dgallium-drivers=panfrost,softpipe,llvmpipe -Dlibunwind=disabled -Dplatforms=x11,wayland -Dprefix=/opt/panfrost
		meson install
	else
		echo "installing mesa from canned image"
		mkdir -p /opt/panfrost/lib/aarch64-linux-gnu
		cp /tmp/overlay/saturncm5/mesa_build/libs.tar					/opt/panfrost/lib/aarch64-linux-gnu/
		cd /opt/panfrost/lib/aarch64-linux-gnu
		tar -xf libs.tar && cd libs && mv * ../ && cd .. && rm -R libs
		rm libs.tar	
		mkdir -p /opt/panfrost/include
		cp -R /tmp/overlay/saturncm5/mesa_build/include/*				/opt/panfrost/include/
		mkdir -p /opt/panfrost/share
		cp -R /tmp/overlay/saturncm5/mesa_build/share/*					/opt/panfrost/share/
	fi
	echo /opt/panfrost/lib/aarch64-linux-gnu | sudo tee					/etc/ld.so.conf.d/0-panfrost.conf
	# correct login banner
	mkdir -p /etc/update-motd.d
	cp  /tmp/overlay/saturncm5/30-armbian-sysinfo						/etc/update-motd.d/
	chmod 755 /etc/update-motd.d/30-armbian-sysinfo
	# WSJT-X
	echo "compiling wsjtx"
	[ -f /tmp/overlay/saturncm5/wsjtx-2.6.1.tar ] && {
		tar -x -f /tmp/overlay/saturncm5/wsjtx-2.6.1.tar -C				/var/data/src/
		cd /var/data/src
		chown -R pi:pi													wsjtx-2.6.1
		chmod -R 755													wsjtx-2.6.1
		cd wsjtx-2.6.1/build
		sudo cmake --install wsjtx-prefix/src/wsjtx-build			
	}
	# xdma2, make symbolic links in /dev
	cp /tmp/overlay/saturncm5/60-xdma.rules								/etc/udev/rules.d/
	if [[ $XDMA -eq 2 ]] 
	then
		cp /tmp/overlay/saturncm5/xdma-udev-command.sh_card20			/etc/udev/xdma-udev-command.sh
	else
		cp /tmp/overlay/saturncm5/xdma-udev-command.sh					/etc/udev/xdma-udev-command.sh	
	fi
	chmod 755															/etc/udev/xdma-udev-command.sh
	# Frontpanels; create symbolic links for USB
	cp /tmp/overlay/saturncm5/SerialUSB/61-g2-serial.rules				/etc/udev/rules.d/
	# backlight regulation
	[[ $FRT -eq 7 ]] || [[ $FRT -eq 8 ]] && {
		cp /tmp/overlay/saturncm5/62-g2-backlight.rules					/etc/udev/rules.d/
	}
	# Themes
	cd /tmp/overlay/saturncm5/
	cp -R Adwaita_Custom_Light											/usr/share/themes/
	cp -R Adwaita_Custom_Dark											/usr/share/themes/	
	# uInitrd Ramdisk
	mkdir -p /usr/share/initramfs-tools/
	cp /tmp/overlay/saturncm5/init										/usr/share/initramfs-tools/	
	chmod 755 /usr/share/initramfs-tools/init
	# RTL8125BG ethernet driver in case of OrangePi5 plus
	[[ $RTL8125 -eq 1 ]] && [[ -d /tmp/overlay/saturncm5/r8125-9.018.00 ]] && {
		echo "compiling RTL8125 2.5 G ethernet driver"
		[ -d /var/data/src/r8125-9.018.00 ] && {
			rm -Rf /var/data/src/r8125-9.018.00
		}
		cp -R /tmp/overlay/saturncm5/r8125-9.018.00						/var/data/src/
		cd /lib/modules/7.1.3-edge-rockchip64/build
		ln -s /boot/System.map-7.1.3-edge-rockchip64					System.map
		cd /var/data/src/r8125-9.018.00
		make
		make install
        echo "blacklist r8169" | sudo tee -a /etc/modprobe.d/blacklist-realtek.conf
	}
}

set_saturn_parms() {
	# XDMA 2: driver module is called xdma2 and kernel presents is as /dev/xdma20...; else /dev/xdma0
	XDMA='2'
	if [[ "${BOARD:0:22}" == "saturn-radxa-cm5-0inch" ]]; then
		FRT=0
	fi
	if [[ "${BOARD:0:22}" == "saturn-radxa-cm5-7inch" ]]; then
		FRT=7
	fi
	if [[ "${BOARD:0:22}" == "saturn-radxa-cm5-8inch" ]]; then
		FRT=8
	fi
	if [[ "${BOARD:0:12}" == "saturn-opi5p" ]]; then
		FRT=8
		RTL8125=1
	fi
}
			
Main() {
	case $RELEASE in
		trixie)
			if [[ "${BOARD:0:6}" == "saturn" ]]; then
				set_saturn_parms
				saturncm5
			fi
			;;
	esac
} # Main

Main "$@"
