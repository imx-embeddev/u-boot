/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Copyright (C) 2016 Freescale Semiconductor, Inc.
 * Copyright 2017,2019 NXP
 *
 * Configuration settings for the Freescale i.MX6UL 14x14 EVK board.
 */
#ifndef __MX6ULL_ALPHA_EMMC_CONFIG_H
#define __MX6ULL_ALPHA_EMMC_CONFIG_H


#include <asm/arch/imx-regs.h>
#include <linux/sizes.h>
#include "mx6_common.h"          /* 如果在 mx6ull_alpha_emmc.h 中没有发现配置某个功能或命令，但是实际却存在的话，可以到 mx6_common.h 文件里面去找一下 */
#include <asm/mach-imx/gpio.h>
#include "imx_env.h"

#ifdef CONFIG_SECURE_BOOT
#ifndef CONFIG_CSF_SIZE
#define CONFIG_CSF_SIZE 0x4000
#endif
#endif

//#define is_mx6ull_9x9_evk()	CONFIG_IS_ENABLED(TARGET_MX6ULL_9X9_EVK)
#define is_mx6ull_alpha_emmc()	CONFIG_IS_ENABLED(TARGET_MX6ULL_ALPHA_EMMC)
/* 设置 DRAM 的大小，宏 PHYS_SDRAM_SIZE 就是板子上 DRAM 的大小
   如果用的 NXP 官方的 9X9 EVK 开发板的话 DRAM 大小就为 256MB。否则的话默认为 512MB，
   正点原子的 I.MX6U-ALPHA 开发板用的是 512MB DDR3。 */
#ifdef CONFIG_TARGET_MX6ULL_9X9_EVK
#define PHYS_SDRAM_SIZE		SZ_256M
#define BOOTARGS_CMA_SIZE   "cma=96M "
#else
#define PHYS_SDRAM_SIZE		SZ_512M
#define BOOTARGS_CMA_SIZE   ""
/* DCDC used on 14x14 EVK, no PMIC */
#undef CONFIG_LDO_BYPASS_CHECK
#endif

/* Size of malloc() pool */
#define CONFIG_SYS_MALLOC_LEN		(16 * SZ_1M) /* malloc 内存池大小，这里设置为 16MB */

/* 使能 I.MX6ULL 的串口功能 */
#define CONFIG_MXC_UART
#define CONFIG_MXC_UART_BASE		UART1_BASE       /* 表示串口寄存器基地址，这里使用的串口 1，基地址为 UART1_BASE */

/* MMC Configs */
#ifdef CONFIG_FSL_USDHC
#define CONFIG_SYS_FSL_ESDHC_ADDR	USDHC2_BASE_ADDR /* EMMC 所使用接口的寄存器基地址，也就是 USDHC2 的基地址(EMMC接在I.MX6ULL的USDHC2上，) */

/* NAND pin conflicts with usdhc2 */
#ifdef CONFIG_CMD_NAND
#define CONFIG_SYS_FSL_USDHC_NUM	1
#else
#define CONFIG_SYS_FSL_USDHC_NUM	2
#endif
#endif

/* I2C configs */
#ifdef CONFIG_CMD_I2C
#define CONFIG_SYS_I2C_MXC
#define CONFIG_SYS_I2C_MXC_I2C1		/* enable I2C bus 1 */
#define CONFIG_SYS_I2C_MXC_I2C2		/* enable I2C bus 2 */
#define CONFIG_SYS_I2C_SPEED		100000
#endif

#define CONFIG_SYS_MMC_IMG_LOAD_PART	1

#ifdef CONFIG_NAND_BOOT
#define MFG_NAND_PARTITION "mtdparts=gpmi-nand:64m(nandboot),16m(nandkernel),16m(nanddtb),16m(nandtee),-(nandrootfs)"
#else
#define MFG_NAND_PARTITION ""
#endif

#define CONFIG_CMD_READ
#define CONFIG_SERIAL_TAG
#define CONFIG_FASTBOOT_USB_DEV 0

#define CONFIG_MFG_ENV_SETTINGS \
	CONFIG_MFG_ENV_SETTINGS_DEFAULT \
	"initrd_addr=0x86800000\0" \
	"initrd_high=0xffffffff\0" \
	"emmc_dev=1\0"\
	"emmc_ack=1\0"\
	"sd_dev=1\0" \
	"mtdparts=" MFG_NAND_PARTITION \
	"\0"\

#if defined(CONFIG_NAND_BOOT)
#define CONFIG_EXTRA_ENV_SETTINGS \
	CONFIG_MFG_ENV_SETTINGS \
	TEE_ENV \
	"panel=TFT43AB\0" \
	"fdt_addr=0x83000000\0" \
	"fdt_high=0xffffffff\0"	  \
	"tee_addr=0x84000000\0" \
	"console=ttymxc0\0" \
	"bootargs=console=ttymxc0,115200 ubi.mtd=4 "  \
		"root=ubi0:rootfs rootfstype=ubifs "		     \
		BOOTARGS_CMA_SIZE \
		MFG_NAND_PARTITION \
		"\0" \
	"bootcmd=nand read ${loadaddr} 0x4000000 0x800000;"\
		"nand read ${fdt_addr} 0x5000000 0x100000;"\
		"if test ${tee} = yes; then " \
			"nand read ${tee_addr} 0x6000000 0x400000;"\
			"bootm ${tee_addr} - ${fdt_addr};" \
		"else " \
			"bootz ${loadaddr} - ${fdt_addr};" \
		"fi\0"

#else
#define CONFIG_EXTRA_ENV_SETTINGS \
	CONFIG_MFG_ENV_SETTINGS \
	TEE_ENV \
	"script=boot.scr\0" \
	"image=zImage\0" \
	"console=ttymxc0\0" \
	"fdt_high=0xffffffff\0" \
	"initrd_high=0xffffffff\0" \
	"fdt_file=undefined\0" \
	"fdt_addr=0x83000000\0" \
	"tee_addr=0x84000000\0" \
	"tee_file=undefined\0" \
	"boot_fdt=try\0" \
	"ip_dyn=yes\0" \
	"panel=TFT43-800x480\0" \
	"mmcdev="__stringify(CONFIG_SYS_MMC_ENV_DEV)"\0" \
	"mmcpart=" __stringify(CONFIG_SYS_MMC_IMG_LOAD_PART) "\0" \
	"mmcroot=" CONFIG_MMCROOT " rootwait rw\0" \
	"mmcautodetect=yes\0" \
	"mmcargs=setenv bootargs console=${console},${baudrate} " \
		BOOTARGS_CMA_SIZE \
		"root=${mmcroot}\0" \
	"loadbootscript=" \
		"fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} ${script};\0" \
	"bootscript=echo Running bootscript from mmc ...; " \
		"source\0" \
	"loadimage=fatload mmc ${mmcdev}:${mmcpart} ${loadaddr} ${image}\0" \
	"loadfdt=fatload mmc ${mmcdev}:${mmcpart} ${fdt_addr} ${fdt_file}\0" \
	"loadtee=fatload mmc ${mmcdev}:${mmcpart} ${tee_addr} ${tee_file}\0" \
	"mmcboot=echo Booting from mmc ...; " \
		"run mmcargs; " \
		"if test ${tee} = yes; then " \
			"run loadfdt; run loadtee; bootm ${tee_addr} - ${fdt_addr}; " \
		"else " \
			"if test ${boot_fdt} = yes || test ${boot_fdt} = try; then " \
				"if run loadfdt; then " \
					"bootz ${loadaddr} - ${fdt_addr}; " \
				"else " \
					"if test ${boot_fdt} = try; then " \
						"bootz; " \
					"else " \
						"echo WARN: Cannot load the DT; " \
					"fi; " \
				"fi; " \
			"else " \
				"bootz; " \
			"fi; " \
		"fi;\0" \
	"netargs=setenv bootargs console=${console},${baudrate} " \
		BOOTARGS_CMA_SIZE \
		"root=/dev/nfs " \
	"ip=dhcp nfsroot=${serverip}:${nfsroot},v3,tcp\0" \
		"netboot=echo Booting from net ...; " \
		"${usb_net_cmd}; " \
		"run netargs; " \
		"if test ${ip_dyn} = yes; then " \
			"setenv get_cmd dhcp; " \
		"else " \
			"setenv get_cmd tftp; " \
		"fi; " \
		"${get_cmd} ${image}; " \
		"if test ${tee} = yes; then " \
			"${get_cmd} ${tee_addr} ${tee_file}; " \
			"${get_cmd} ${fdt_addr} ${fdt_file}; " \
			"bootm ${tee_addr} - ${fdt_addr}; " \
		"else " \
			"if test ${boot_fdt} = yes || test ${boot_fdt} = try; then " \
				"if ${get_cmd} ${fdt_addr} ${fdt_file}; then " \
					"bootz ${loadaddr} - ${fdt_addr}; " \
				"else " \
					"if test ${boot_fdt} = try; then " \
						"bootz; " \
					"else " \
						"echo WARN: Cannot load the DT; " \
					"fi; " \
				"fi; " \
			"else " \
				"bootz; " \
			"fi; " \
		"fi;\0" \
		"findfdt="\
			"if test $fdt_file = undefined; then " \
				"if test $board_name = ULZ-EVK && test $board_rev = 14X14; then " \
					"setenv fdt_file imx6ulz-14x14-evk.dtb; fi; " \
				"if test $board_name = EVK && test $board_rev = 9X9; then " \
					"setenv fdt_file imx6ull-9x9-evk.dtb; fi; " \
				"if test $board_name = EVK && test $board_rev = 14X14; then " \
					"setenv fdt_file imx6ull-14x14-evk.dtb; fi; " \
				"if test $fdt_file = undefined; then " \
					"echo WARNING: Could not determine dtb to use; " \
				"fi; " \
			"fi;\0" \
		"findtee="\
			"if test $tee_file = undefined; then " \
				"if test $board_name = ULZ-EVK && test $board_rev = 14X14; then " \
					"setenv tee_file uTee-6ulzevk; fi; " \
				"if test $board_name = EVK && test $board_rev = 9X9; then " \
					"setenv tee_file uTee-6ullevk; fi; " \
				"if test $board_name = EVK && test $board_rev = 14X14; then " \
					"setenv tee_file uTee-6ullevk; fi; " \
				"if test $tee_file = undefined; then " \
					"echo WARNING: Could not determine tee to use; " \
				"fi; " \
			"fi;\0" \

#define CONFIG_BOOTCOMMAND \
	   "run findfdt;" \
	   "run findtee;" \
	   "mmc dev ${mmcdev};" \
	   "mmc dev ${mmcdev}; if mmc rescan; then " \
		   "if run loadbootscript; then " \
			   "run bootscript; " \
		   "else " \
			   "if run loadimage; then " \
				   "run mmcboot; " \
			   "else run netboot; " \
			   "fi; " \
		   "fi; " \
	   "else run netboot; fi"
#endif

/* Miscellaneous configurable options */
#define CONFIG_SYS_MEMTEST_START	0x80000000
#define CONFIG_SYS_MEMTEST_END		(CONFIG_SYS_MEMTEST_START + 0x8000000)

#define CONFIG_SYS_LOAD_ADDR		CONFIG_LOADADDR
#define CONFIG_SYS_HZ			1000     /* 系统时钟频率，这里为 1000Hz */

/* Physical Memory Map */
#define PHYS_SDRAM			MMDC0_ARB_BASE_ADDR

#define CONFIG_SYS_SDRAM_BASE		PHYS_SDRAM
#define CONFIG_SYS_INIT_RAM_ADDR	IRAM_BASE_ADDR
#define CONFIG_SYS_INIT_RAM_SIZE	IRAM_SIZE

#define CONFIG_SYS_INIT_SP_OFFSET \
	(CONFIG_SYS_INIT_RAM_SIZE - GENERATED_GBL_DATA_SIZE)
#define CONFIG_SYS_INIT_SP_ADDR \
	(CONFIG_SYS_INIT_RAM_ADDR + CONFIG_SYS_INIT_SP_OFFSET)

/* environment organization */
#define CONFIG_SYS_MMC_ENV_DEV		1	/* USDHC2 */
#define CONFIG_SYS_MMC_ENV_PART		0	/* user area */
#define CONFIG_MMCROOT			"/dev/mmcblk1p2"  /* USDHC2 */

#define CONFIG_IOMUX_LPSR

#ifdef CONFIG_FSL_QSPI
#define CONFIG_SYS_FSL_QSPI_AHB
#define FSL_QSPI_FLASH_NUM		1
#define FSL_QSPI_FLASH_SIZE		SZ_32M
#endif

/* NAND stuff */
#ifdef CONFIG_NAND_MXS
#define CONFIG_SYS_MAX_NAND_DEVICE	1
#define CONFIG_SYS_NAND_BASE		0x40000000
#define CONFIG_SYS_NAND_5_ADDR_CYCLE
#define CONFIG_SYS_NAND_ONFI_DETECTION

/* DMA stuff, needed for GPMI/MXS NAND support */
#endif

#define CONFIG_ENV_SIZE			SZ_8K
#if defined(CONFIG_ENV_IS_IN_MMC)
#define CONFIG_ENV_OFFSET		(14 * SZ_64K)
#elif defined(CONFIG_ENV_IS_IN_SPI_FLASH)
#define CONFIG_ENV_OFFSET		(896 * 1024)
#define CONFIG_ENV_SECT_SIZE		(64 * 1024)
#define CONFIG_ENV_SPI_BUS		CONFIG_SF_DEFAULT_BUS
#define CONFIG_ENV_SPI_CS		CONFIG_SF_DEFAULT_CS
#define CONFIG_ENV_SPI_MODE		CONFIG_SF_DEFAULT_MODE
#define CONFIG_ENV_SPI_MAX_HZ		CONFIG_SF_DEFAULT_SPEED
#elif defined(CONFIG_ENV_IS_IN_NAND)
#undef CONFIG_ENV_SIZE
#define CONFIG_ENV_OFFSET		(60 << 20)
#define CONFIG_ENV_SECT_SIZE		(128 << 10)
#define CONFIG_ENV_SIZE			CONFIG_ENV_SECT_SIZE
#endif

/* USB Configs */
#ifdef CONFIG_CMD_USB
#define CONFIG_EHCI_HCD_INIT_AFTER_RESET
#define CONFIG_MXC_USB_PORTSC  (PORT_PTS_UTMI | PORT_PTS_PTW)
#define CONFIG_MXC_USB_FLAGS   0
#define CONFIG_USB_MAX_CONTROLLER_COUNT 2
#endif

#ifdef CONFIG_FEC_MXC
#define CONFIG_CMD_MII
#define CONFIG_FEC_ENET_DEV 1 /* 选择使用哪个网口。默认为 1，选择 ENET2；为0时，选择 ENET1 */

#if (CONFIG_FEC_ENET_DEV == 0)
#define IMX_FEC_BASE			ENET_BASE_ADDR
#define CONFIG_FEC_MXC_PHYADDR 0x0 /* ENET1的PHY地址，默认是 0X2，正点原子开发板为0x0，这里修改为0x0 */
#define CONFIG_FEC_XCV_TYPE             RMII
#define CONFIG_ETHPRIME			"eth0"
#elif (CONFIG_FEC_ENET_DEV == 1)
#define IMX_FEC_BASE			ENET2_BASE_ADDR
#define CONFIG_FEC_MXC_PHYADDR 0x1 /* ENET2的PHY地址，默认是 0X1，正点原子开发板为0x1，这里保持不变 */
#define CONFIG_FEC_XCV_TYPE		RMII
#define CONFIG_ETHPRIME			"eth1"
#endif

#define CONFIG_FEC_MXC_MDIO_BASE ENET2_BASE_ADDR
#endif

#define CONFIG_IMX_THERMAL

#ifndef CONFIG_SPL_BUILD
#ifdef CONFIG_VIDEO /* 用于开启 LCD */
#define CONFIG_VIDEO_MXS
#define CONFIG_VIDEO_LOGO /* 使能 LOGO 显示 */
#define CONFIG_SPLASH_SCREEN
#define CONFIG_SPLASH_SCREEN_ALIGN
#define CONFIG_BMP_16BPP
#define CONFIG_VIDEO_BMP_RLE8
#define CONFIG_VIDEO_BMP_LOGO
#define CONFIG_IMX_VIDEO_SKIP
#endif
#endif

#define CONFIG_MODULE_FUSE
#define CONFIG_OF_SYSTEM_SETUP

#endif
