#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : 1.sh
# * Author     : 上上签
# * Date       : 2023-07-25
# * ======================================================
##

SCRIPT_NAME=${0#*/}
SCRIPT_PATH=${0%/*}
##======================================================
BLACK="\033[1;30m"
RED='\033[1;31m'    # 红
GREEN='\033[1;32m'  # 绿
YELLOW='\033[1;33m' # 黄
BLUE='\033[1;34m'   # 蓝
PINK='\033[1;35m'   # 紫
CYAN='\033[1;36m'   # 青
WHITE='\033[1;37m'  # 白
CLS='\033[0m'       # 清除颜色

INFO="${GREEN}INFO  ${CLS}"
WARN="${YELLOW}WARN  ${CLS}"
ERR="${RED}ERROR  ${CLS}"

TARGET=u-boot
TARGET_FILE=${TARGET}.bin
TARGET_IMX_FILE=${TARGET}.imx
IMXDOWNLOAD_TOOL=${SCRIPT_PATH}/tools/imxdownload/imxdownload

SD_NODE=/dev/sdc

ARCH_NAME=arm
CROSS_COMPILE_NAME=arm-linux-gnueabihf-

BOARD_CONFIG_NAME=mx6ull_14x14_evk_emmc_defconfig

function time_count_down
{
    for i in {3..1}
    do     

        echo -ne "${INFO}after ${i} is end!!"
        echo -ne "\r\r"        # echo -e 处理特殊字符  \r 光标移至行首，但不换行
        sleep 1
    done
}
function clean_project()
{
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} distclean
}

function build_project()
{
    if [ -f "${TARGET_FILE}" ];then
        echo -e "${INFO}正在清理工程文件..."
        clean_project
    fi

    echo -e "${INFO}正在配置编译选项(BOARD_CONFIG_NAME=${BOARD_CONFIG_NAME})..."
    make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} ${BOARD_CONFIG_NAME}
    echo -e "${INFO}正在编译工程(BOARD_CONFIG_NAME=${BOARD_CONFIG_NAME})..."
    make V=0 ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} -j16

    echo -e "${INFO}检查是否编译成功..."
    if [ ! -f "${TARGET_FILE}" ];then
        echo -e "${RED}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
        echo -e "${ERR}${TARGET_FILE} 编译失败,请检查后重试"
        echo -e "${RED}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
    else
        echo -e "${GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
        echo -e "${INFO}${TARGET_FILE} 编译成功"
        echo -e "${GREEN}++++++++++++++++++++++++++++++++++++++++++++++++++++${CLS}"
    fi
}

function download_imx()
{
    # 判断编译目标文件是否存在
    if [ ! -e "${SD_NODE}" ];then
        echo -e "${ERR}${SD_NODE}不存在,请检查SD卡是否插入..."
        return
    fi
    # 检查imx文件是否存在
    if [ ! -f "${TARGET_IMX_FILE}" ];then
        echo -e "${ERR}${TARGET_IMX_FILE} 不存在,请检查后再下载..."
        return
    fi
    echo -e "${INFO}3s后开始下载 ${TARGET_IMX_FILE} 到 ${SD_NODE}..."
    time_count_down
    sudo dd if=${TARGET_IMX_FILE} of=${SD_NODE} bs=1k seek=1 conv=fsync
}

function download_bin()
{
    # 判断编译目标文件是否存在
    if [ ! -e "${SD_NODE}" ];then
        echo -e "${ERR}${SD_NODE}不存在,请检查SD卡是否插入..."
        return
    fi
    # 检查bin文件是否存在
    if [ ! -f "${TARGET_FILE}" ];then
        echo -e "${ERR}${TARGET_FILE} 不存在,请检查后再下载..."
        return
    fi

    ${IMXDOWNLOAD_TOOL} ${TARGET_FILE} ${SD_NODE}

}

function build_download_project()
{
    build_project
    download_imx
}

function build_NXP_uboot()
{
    BOARD_CONFIG_NAME=mx6ull_14x14_evk_emmc_defconfig
    build_project
    download_imx
}

function build_ALPHA_uboot()
{
    BOARD_CONFIG_NAME=mx6ull_alpha_emmc_defconfig
    build_project
    download_imx
}

function echo_menu()
{
    echo "================================================="
	echo -e "${GREEN}               build project ${CLS}"
	echo -e "${GREEN}                by @上上签    ${CLS}"
	echo "================================================="
    echo -e "${PINK}current path       :$(pwd)${CLS}"
    echo -e "${PINK}SCRIPT_PATH        :${SCRIPT_PATH}${CLS}"
    echo -e "${PINK}ARCH_NAME          :${ARCH_NAME}${CLS}"
    echo -e "${PINK}CROSS_COMPILE_NAME :${CROSS_COMPILE_NAME}${CLS}"
    echo -e "${PINK}BOARD_CONFIG_NAME  :${BOARD_CONFIG_NAME}${CLS}"
    echo ""
    echo -e "* [0] 编译uboot工程"
    echo -e "* [1] 清理uboot工程"
    echo -e "* [2] 编译NXP官方原版uboot工程"
    echo "================================================="
}

function func_process()
{
	read -p "请选择功能,默认选择0:" choose
	case "${choose}" in
		"0") build_ALPHA_uboot;;
		"1") clean_project;;
		"2") build_NXP_uboot;;
		*) build_ALPHA_uboot;;
	esac
}

echo_menu
func_process
