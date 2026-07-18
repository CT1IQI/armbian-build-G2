# Rockchip RK3588 octa core 4/8/16GB RAM SoC SPI NVMe 2x USB2 2x USB3 1x USB-C 2x 2.5GbE 3x HDMI
BOARD_NAME="Saturn Orange Pi 5 Plus, 8 inch control front"
BOARD_VENDOR="xunlong"
BOARDFAMILY="rockchip-rk3588"
BOOT_SOC="rk3588"
KERNEL_TARGET="current,edge,vendor"
KERNEL_TEST_TARGET="vendor,current"
# vendor name, not standard, see hook below, set BOOT_SOC below to compensate
BOOTCONFIG="saturn-opi5p-rk3588_defconfig"
BOOT_SOC="rk3588"
BOOT_FDT_FILE="rockchip/rk3588-saturn-opi5p-8inch-k701.dtb"
BOOT_SCENARIO="spl-blobs"
BOOT_LOGO="no"
BOOT_SUPPORT_SPI="yes"
BOOT_SPI_RKSPI_LOADER="yes"
IMAGE_PARTITION_TABLE="gpt"
FULL_DESKTOP='no'

function post_family_config__saturn-opi5p_use_mainline_uboot() {
	[[ "${BRANCH}" == "vendor" ]] && return 0 # skip for vendor branch

	display_alert "$BOARD" "Mainline U-Boot overrides for $BOARD - $BRANCH" "info"

	# To reuse ATF code in rockchip64_common, let's change the BOOT_SCENARIO and call prepare_boot_configuration() again
	declare -g BOOT_SCENARIO="tpl-blob-atf-mainline"
	prepare_boot_configuration
	declare -g BOOTSCRIPT='boot-saturn-opi5p-rk3588.cmd:boot.cmd'
	declare -g BOOTENV_FILE='saturn-opi5p-rk3588.txt'
#	declare -g BOOTCONFIG="saturn-opi5p-rk3588_defconfig"
	declare -g BOOTCONFIG="orangepi-5-plus-rk3588_defconfig"
	declare -g BOOTDELAY=1
	declare -g BOOTSOURCE="https://github.com/u-boot/u-boot.git"
#	declare -g BOOTBRANCH="tag:v2026.04"
	declare -g BOOTBRANCH="tag:v2026.01"
#	declare -g BOOTPATCHDIR="v2026.04"
	declare -g BOOTPATCHDIR="v2026.01"
	declare -g BOOTDIR="u-boot-${BOARD}"
#	declare -g UBOOT_TARGET_MAP="BL31=${RKBIN_DIR}/${BL31_BLOB} ROCKCHIP_TPL=${RKBIN_DIR}/${DDR_BLOB};;u-boot-rockchip.bin"
	declare -g UBOOT_TARGET_MAP="BL31=bl31.elf ROCKCHIP_TPL=${RKBIN_DIR}/${DDR_BLOB};;u-boot-rockchip.bin"
	unset uboot_custom_postprocess write_uboot_platform write_uboot_platform_mtd # disable stuff from rockchip64_common; we're using binman here which does all the work already

	# Just use the binman-provided u-boot-rockchip.bin, which is ready-to-go
	function write_uboot_platform() {
		dd "if=$1/u-boot-rockchip.bin" "of=$2" bs=32k seek=1 conv=notrunc status=none
	}

	function write_uboot_platform_mtd() {
		flashcp -v -p "$1/u-boot-rockchip-spi.bin" /dev/mtd0
	}
}

function pre_config_uboot_target__rockchip_common_boot_order() {
	declare -a rockchip_uboot_targets=("mmc1" "mmc0" "nvme" "scsi" "usb" "pxe" "dhcp") # mmc1=SD, mmc0=eMMC
	display_alert "u-boot for ${BOARD}/${BRANCH}" "u-boot: adjust boot order to '${rockchip_uboot_targets[*]}'" "info"
	sed -i -e "s/#define BOOT_TARGETS.*/#define BOOT_TARGETS \"${rockchip_uboot_targets[*]}\"/" include/configs/rockchip-common.h
	regular_git diff -u include/configs/rockchip-common.h || true
}

function post_family_tweaks__orangepi5plus_naming_audios() {
	display_alert "$BOARD" "Renaming orangepi5 audios" "info"

	mkdir -p $SDCARD/etc/udev/rules.d/
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi0-sound", ENV{SOUND_DESCRIPTION}="HDMI0 Audio"' > $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmi1-sound", ENV{SOUND_DESCRIPTION}="HDMI1 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-hdmiin-sound", ENV{SOUND_DESCRIPTION}="HDMI-In Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-dp0-sound", ENV{SOUND_DESCRIPTION}="DP0 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules
	echo 'SUBSYSTEM=="sound", ENV{ID_PATH}=="platform-es8388-sound", ENV{SOUND_DESCRIPTION}="ES8388 Audio"' >> $SDCARD/etc/udev/rules.d/90-naming-audios.rules

	return 0
}

