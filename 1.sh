#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : build.sh
# * Author     : 苏木
# * Date       : 2025-04-18
# * ======================================================
##

# 颜色和日志标识
# ========================================================
# |  ---  | 黑色  | 红色 |  绿色 |  黄色 | 蓝色 |  洋红 | 青色 | 白色  |
# | 前景色 |  30  |  31  |  32  |  33  |  34  |  35  |  35  |  37  |
# | 背景色 |  40  |  41  |  42  |  43  |  44  |  45  |  46  |  47  |
BLACK="\033[1;30m"
RED='\033[1;31m'    # 红
GREEN='\033[1;32m'  # 绿
YELLOW='\033[1;33m' # 黄
BLUE='\033[1;34m'   # 蓝
PINK='\033[1;35m'   # 紫
CYAN='\033[1;36m'   # 青
WHITE='\033[1;37m'  # 白
CLS='\033[0m'       # 清除颜色

INFO="${GREEN}INFO: ${CLS}"
WARN="${YELLOW}WARN: ${CLS}"
ERROR="${RED}ERROR: ${CLS}"

# 脚本和工程路径
# ========================================================
SCRIPT_NAME=${0#*/}
SCRIPT_CURRENT_PATH=${0%/*}
SCRIPT_ABSOLUTE_PATH=`cd $(dirname ${0}); pwd`
PROJECT_ROOT=${SCRIPT_ABSOLUTE_PATH} # 工程的源码目录，一定要和编译脚本是同一个目录
SOFTWARE_DIR_PATH=~/2software        # 软件安装目录
TFTP_DIR=~/3tftp
NFS_DIR=~/4nfs
CPUS=$(($(nproc)-1))                 # 使用总核心数-1来多线程编译
# 可用的emoji符号
# ========================================================
function usage_emoji()
{
    echo -e "⚠️ ✅ 🚩 📁 🕣️"
}

# 时间计算
# ========================================================
TIME_START=
TIME_END=

function get_start_time()
{
	TIME_START=$(date +'%Y-%m-%d %H:%M:%S')
}

function get_end_time()
{
	TIME_END=$(date +'%Y-%m-%d %H:%M:%S')
}

function get_execute_time()
{
	start_seconds=$(date --date="$TIME_START" +%s);
	end_seconds=$(date --date="$TIME_END" +%s);
	duration=`echo $(($(date +%s -d "${TIME_END}") - $(date +%s -d "${TIME_START}"))) | awk '{t=split("60 s 60 m 24 h 999 d",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}'`
	echo "===*** 🕣️ 运行时间：$((end_seconds-start_seconds))s,time diff: ${duration} ***==="
}

function time_count_down
{
    for i in {3..0}
    do     

        echo -ne "${INFO}after ${i} is end!!!"
        echo -ne "\r\r"        # echo -e 处理特殊字符  \r 光标移至行首，但不换行
        sleep 1
    done
    echo "" # 打印一个空行，防止出现混乱
}

function get_run_time_demo()
{
    get_start_time
    time_count_down
    get_end_time
    get_execute_time
}

# 开发环境信息
# ========================================================
function get_ubuntu_info()
{
    local kernel_version=$(uname -r) # 获取内核版本信息，-a选项会获得更详细的版本信息
    local ubuntu_version=$(lsb_release -ds) # 获取Ubuntu版本信息

    
    local ubuntu_ram_total=$(cat /proc/meminfo |grep 'MemTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g')   # 获取Ubuntu RAM大小
    local ubuntu_swap_total=$(cat /proc/meminfo |grep 'SwapTotal' |awk -F : '{print $2}' |sed 's/^[ \t]*//g') # 获取Ubuntu 交换空间swap大小
    #local ubuntu_disk=$(sudo fdisk -l |grep 'Disk' |awk -F , '{print $1}' | sed 's/Disk identifier.*//g' | sed '/^$/d') #显示硬盘，以及大小
    local ubuntu_cpu=$(grep 'model name' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g' |sed 's/ \+/ /g') #cpu型号
    local ubuntu_physical_id=$(grep 'physical id' /proc/cpuinfo |sort |uniq |wc -l) #物理cpu个数
    local ubuntu_cpu_cores=$(grep 'cpu cores' /proc/cpuinfo |uniq |awk -F : '{print $2}' |sed 's/^[ \t]*//g') #物理cpu内核数
    local ubuntu_processor=$(grep 'processor' /proc/cpuinfo |sort |uniq |wc -l) #逻辑cpu个数(线程数)
    local ubuntu_cpu_mode=$(getconf LONG_BIT) #查看CPU当前运行模式是64位还是32位

    # 打印结果
    echo -e "ubuntu: $ubuntu_version - $ubuntu_cpu_mode"
    echo -e "kernel: $kernel_version"
    echo -e "ram   : $ubuntu_ram_total"
    echo -e "swap  : $ubuntu_swap_total"
    echo -e "cpu   : $ubuntu_cpu,physical id is$ubuntu_physical_id,cores is $ubuntu_cpu_cores,processor is $ubuntu_processor"
}

# 本地虚拟机VMware开发环境信息
function get_dev_env_info()
{
    echo "Development environment: "
    echo "ubuntu : 20.04.2-64(1核12线程 16GB RAM,512GB SSD) arm"
    echo "VMware : VMware® Workstation 17 Pro 17.6.0 build-24238078"
    echo "Windows: "
    echo "          处理器 AMD Ryzen 7 5800H with Radeon Graphics 3.20 GHz 8核16线程"
    echo "          RAM	32.0 GB (31.9 GB 可用)"
    echo "          系统类型	64 位操作系统, 基于 x64 的处理器"
    echo "linux开发板原始系统组件版本:"
    echo "          uboot : v2019.04 https://github.com/nxp-imx/uboot-imx/releases/tag/rel_imx_4.19.35_1.1.0"
    echo "          kernel: v4.19.71 https://github.com/nxp-imx/linux-imx/releases/tag/v4.19.71"
    echo "          rootfs: buildroot-2023.05.1 https://buildroot.org/downloads/buildroot-2023.05.1.tar.gz"
    echo ""
    echo "x86_64-linux-gnu   : gcc version 9.4.0 (Ubuntu 9.4.0-1ubuntu1~20.04.2)"
    echo "arm-linux-gnueabihf:"
    echo "          arm-linux-gnueabihf-gcc 8.3.0"
    echo "          https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz"
}

# 环境变量
# ========================================================
# Github Actions托管的linux服务器有以下用户级环境变量，系统级环境变量加上sudo好像也权限修改
# .bash_logout  当用户注销时，此文件将被读取，通常用于清理工作，如删除临时文件。
# .bashrc       此文件包含特定于 Bash Shell 的配置，如别名和函数。它在每次启动非登录 Shell 时被读取。
# .profile、.bash_profile 这两个文件位于用户的主目录下，用于设置特定用户的环境变量和启动程序。当用户登录时，
#                        根据 Shell 的类型和配置，这些文件中的一个或多个将被读取。
USER_ENV=(~/.bashrc ~/.profile ~/.bash_profile)
SYSENV=(/etc/profile) # 系统环境变量位置
ENV_FILE=("${USER_ENV[@]}" "${SYSENV[@]}")

function source_env_info()
{
    for temp in ${ENV_FILE[@]};
    do
        if [ -f ${temp} ]; then
            echo -e "${INFO}source ${temp}"
            source ${temp}
        fi
    done
}

# ========================================================
# U-Boot 编译
# ========================================================
TARGET=u-boot
TARGET_IMX_FILE=${TARGET}-dtb.imx

RESULT_OUTPUT=image_output
RESULT_FILE=(u-boot.bin u-boot-dtb.bin u-boot-dtb.imx)
BOARD_DEFCONFIG=mx6ull_alpha_emmc_defconfig
BOARD_NAME=alpha

ARCH_NAME=arm
CROSS_COMPILE_NAME=arm-linux-gnueabihf-

SD_NODE=/dev/sdc

COMPILE_PLATFORM=local # local：非githubaction自动打包，githubaction：githubaction自动打包
COMPILE_MODE=0         # 0,清除工程后编译，1,不清理直接编译
DOWNLOAD_SDCARD=0      # 0,不执行下载到sd卡的流程，1,编译完执行下载到sd卡流程
REDIRECT_LOG_FILE=
COMMAND_EXIT_CODE=0    # 要有一个初始值，不然可能会报错
V=0                    # 主要是保存到日志文件的时候可以改成1，这样可以看到更加详细的日志
# 脚本参数传入处理
# ========================================================
function usage()
{
	echo -e "================================================="
    echo -e "${PINK}./1.sh       : 根据菜单编译工程${CLS}"
    echo -e "${PINK}./1.sh -d    : 编译后下载到sd卡${CLS}"
    echo -e "${PINK}./1.sh -p 1  : githubaction自动编译工程${CLS}"
    echo -e "${PINK}./1.sh -m 1  : 增量编译，不清理工程，不重新配置${CLS}"
    echo -e ""
    echo -e "================================================="
}

# 脚本运行参数处理
echo -e "${CYAN}There are $# parameters: $@ (\$1~\$$#)${CLS}"
while getopts "b:p:m:d" arg #选项后面的冒号表示该选项需要参数
    do
        case ${arg} in
            b)
                if [ $OPTARG == "nxp" ];then
                    BOARD_NAME=NXP
                    BOARD_DEFCONFIG=mx6ull_14x14_evk_defconfig
                fi
                ;;
            p)
                if [ $OPTARG == "1" ];then
                    COMPILE_PLATFORM=githubaction
                    REDIRECT_LOG_FILE="${RESULT_OUTPUT}/u-boot-make-$(date +%Y%m%d_%H%M%S).log"
                    V=0 # 保存详细日志就这里改成1 
                fi
                ;;
            m)
                if [ $OPTARG == "1" ];then
                    COMPILE_MODE=1
                fi
                ;;
            d)
                DOWNLOAD_SDCARD=1
                ;;
            ?)  #当有不认识的选项的时候arg为?
                echo -e "${ERROR}unkonw argument..."
                exit 1
                ;;
        esac
    done

# 功能实现
# ========================================================
# 不知道为什么当日志和脚本在同一个目录，日志最后就会被删除
function log_redirect_start()
{
    # 启用日志时重定向输出
    if [[ -n "${REDIRECT_LOG_FILE}" ]]; then
        exec 3>&1 4>&2 # 备份原始输出描述符
        echo -e "${BLUE}▶ 编译日志保存到: 📁 ${REDIRECT_LOG_FILE}${CLS}"
        # 初始化日志目录
        if [ ! -d "$RESULT_OUTPUT" ];then
            mkdir -pv "$RESULT_OUTPUT"
        fi
        if [ -s "${REDIRECT_LOG_FILE}" ]; then
            exec >> "${REDIRECT_LOG_FILE}" 2>&1
        else
            exec > "${REDIRECT_LOG_FILE}" 2>&1
        fi
        
        # 日志头存放信息s
        echo -e "=== 开始执行命令 ==="
        echo -e "当前时间: $(date +'%Y-%m-%d %H:%M:%S')"
    fi
}

function log_redirect_recovery()
{
    # 恢复原始输出
    if [[ -n "${REDIRECT_LOG_FILE}" ]]; then
        echo -e "当前时间: $(date +'%Y-%m-%d %H:%M:%S')"
        echo -e "=== 执行命令结束 ==="
        exec 1>&3 2>&4

        # 输出结果
        if [ $1 -eq 0 ]; then
            echo -e "${GREEN}✅ 命令执行成功!${CLS}"
        else
            echo -e "${RED}命令执行成失败 (退出码: $1)${CLS}"
            [[ -n "${REDIRECT_LOG_FILE}" ]] && echo -e "${YELLOW}查看日志: tail -f ${REDIRECT_LOG_FILE}${CLS}"
        fi
        exec 3>&- 4>&- # 关闭备份描述符

        # 验证日志完整性
        if [[ -n "${REDIRECT_LOG_FILE}" ]]; then
            if [[ ! -s "${REDIRECT_LOG_FILE}" ]]; then
                echo -e "${YELLOW}⚠ 警告: 日志文件为空，可能未捕获到输出${CLS}"
            else
                echo -e "${BLUE}📁 日志大小: $(du -h "${REDIRECT_LOG_FILE}" | cut -f1)${CLS}"
            fi
        fi
    fi
}

function arm_gcc_check()
{
    echo -e "${INFO}▶ 验证工具链版本..."
    if arm-linux-gnueabihf-gcc --version &> /dev/null; then
        echo -e "${GREEN}✅ 验证成功！工具链版本信息：${CLS}"
        arm-linux-gnueabihf-gcc --version | head -n1
    else
        echo -e "${RED}工具链验证失败，请手动执行以下命令：${CLS}"
        echo "source ~/.bashrc 或重新打开终端"
        exit 1
    fi
}

function uboot_project_clean()
{
    (
        cd ${PROJECT_ROOT}
        # 增量编译直接返回
        if [ ${COMPILE_MODE} == "1" ] && [ -z $1 ]; then
            return
        fi

        echo ""
        echo -e "🚩 ===> function ${FUNCNAME[0]}"
        echo -e "${PINK}current path :$(pwd)${CLS}"
        echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"
        
        # 1. 删除成果物目录 image_output
        if [ -d "${RESULT_OUTPUT}" ];then
            rm -rvf  ${RESULT_OUTPUT}
        fi

        # 2. 清理整个工程
        echo -e "${INFO}▶ make V=${V} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean"
        log_redirect_start
        make ARCH=arm V=${V} CROSS_COMPILE=arm-linux-gnueabihf- distclean || COMMAND_EXIT_CODE=$?
        log_redirect_recovery ${COMMAND_EXIT_CODE}
        # make ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} clean
    )
}

# 说明：Kconfig中默认为y的参数不会被保存到defconfig中，即便默认配置文件没有对应的选项，在执行了默认配置文件后
# 也依然会被选中
function uboot_savedefconfig()
{
    (
        cd ${PROJECT_ROOT}
        echo ""
        echo -e "🚩 ===> function ${FUNCNAME[0]}"
        echo -e "${PINK}current path :$(pwd)${CLS}"
        echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

        # 保存默认配置文件
        echo -e "${INFO}▶ make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} savedefconfig"
        log_redirect_start
        make V=${V} ARCH=${ARCH_NAME} CROSS_COMPILE=${CROSS_COMPILE_NAME} savedefconfig || COMMAND_EXIT_CODE=$?
        log_redirect_recovery ${COMMAND_EXIT_CODE}

        if [ ! -d "${RESULT_OUTPUT}" ];then
            mkdir -pv ${RESULT_OUTPUT}
        fi
        
        echo -e "${INFO}▶ 拷贝配置文件到 ${RESULT_OUTPUT} 目录"
        if [ -f "defconfig" ]; then
            cp -avf defconfig ${RESULT_OUTPUT}/${BOARD_DEFCONFIG}
        fi
        cp -avf .config ${RESULT_OUTPUT}
    )
}

function download_imx2sd()
{
    (
        cd ${PROJECT_ROOT}

        if [ ${DOWNLOAD_SDCARD} == '0' ];then
            return
        fi

        echo ""
        echo -e "🚩 ===> function ${FUNCNAME[0]}"
        echo -e "${PINK}current path :$(pwd)${CLS}"
        echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

        # 1. 检查SD卡节点
        echo -e "${YELLOW}▶ 查看sd相关节点, 将使用${SD_NODE},3秒后继续...${CLS}"
        ls /dev/sd*
        time_count_down

        # 2. 判断SD卡节点是否存在
        if [ ! -e "${SD_NODE}" ];then
            echo -e "${RED}${SD_NODE}不存在,请检查SD卡是否插入...${CLS}"
            return
        fi

        # 3. 检查imx文件是否存在
        if [ ! -f "${TARGET_IMX_FILE}" ];then
            echo -e "${ERR}${TARGET_IMX_FILE} 不存在,请检查后再下载..."
            return
        fi
        echo -e "${INFO}⬇️  3s后开始下载 ${TARGET_IMX_FILE} 到 ${SD_NODE}..."
        time_count_down
        # sudo dd if=u-boot-dtb.imx of=/dev/sdc bs=1k seek=1 conv=fsync
        echo -e "${INFO}▶ sudo dd if=${TARGET_IMX_FILE} of=${SD_NODE} bs=1k seek=1 conv=fsync"
        sudo dd if=${TARGET_IMX_FILE} of=${SD_NODE} bs=1k seek=1 conv=fsync
    )
}

function download_imx2tftp()
{
    (
        cd ${PROJECT_ROOT}
        echo ""
        echo -e "🚩 ===> function ${FUNCNAME[0]}"
        echo -e "${PINK}current path :$(pwd)${CLS}"
        echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

        # 1. 检查tftp目录是否存在
        if [ ! -d "${TFTP_DIR}" ];then
            mkdir -pv ${TFTP_DIR}
        fi

        # 2. 检查imx文件是否存在
        if [ ! -f "${TARGET_IMX_FILE}" ];then
            echo -e "${ERR}${TARGET_IMX_FILE} 不存在,请检查后再下载..."
            return
        fi
        cp -avf ${TARGET_IMX_FILE} ${TFTP_DIR}
    )
}

function uboot_build()
{
    (
        cd ${PROJECT_ROOT}
        echo ""
        echo -e "🚩 ===> function ${FUNCNAME[0]}"
        echo -e "${PINK}current path :$(pwd)${CLS}"
        echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

        get_start_time
        uboot_project_clean # 清理工程

        # 2. 清理整个工程
        echo -e "${INFO}▶ make V=${V} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- ${BOARD_DEFCONFIG}"
        echo -e "${INFO}▶ make V=${V} ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j${CPUS}"
        log_redirect_start
        make ARCH=arm V=${V} CROSS_COMPILE=arm-linux-gnueabihf- ${BOARD_DEFCONFIG} || COMMAND_EXIT_CODE=$?
        make ARCH=arm V=${V} CROSS_COMPILE=arm-linux-gnueabihf- -j${CPUS} || COMMAND_EXIT_CODE=$?
        log_redirect_recovery ${COMMAND_EXIT_CODE}

        echo -e "${INFO}▶ 检查是否编译成功..."
        if [ ! -f "${TARGET_IMX_FILE}" ];then
            echo -e "${RED}❌ ${TARGET_IMX_FILE} 编译失败,请检查后重试!${CLS}"
        else
            echo -e "✅ ${TARGET_IMX_FILE} 编译成功!"
        fi

        get_end_time
        get_execute_time
    )
}

function update_result_file()
{
    (
        cd ${PROJECT_ROOT}
        echo ""
        echo -e "🚩 ===> function ${FUNCNAME[0]}"
        echo -e "${PINK}current path :$(pwd)${CLS}"
        echo -e "${PINK}board_config :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"

        # 成果物文件拷贝
        echo -e "${INFO}▶ 检查并拷贝 ${RESULT_FILE[*]} 到 ${RESULT_OUTPUT}"
        if [ ! -d "${RESULT_OUTPUT}" ];then
            mkdir -pv ${RESULT_OUTPUT}
        fi
        for temp in "${RESULT_FILE[@]}";
        do
            if [ -f "${temp}" ];then
                cp -avf ${temp} ${RESULT_OUTPUT}
            else
                echo -e "${RED}${temp} 不存在 ${CLS}"
            fi
        done

        # 开始判断并打包文件
        # 1.获取父目录绝对路径，判断是否是 Git 仓库并获取版本号
        parent_dir=$(dirname "$(realpath "${RESULT_OUTPUT}")")
        if git -C "$parent_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            version=$(git -C "$parent_dir" rev-parse --short HEAD)
        else
            version="unknown"
        fi

        # 2. 生成时间戳（格式：年月日时分秒）
        timestamp=$(date +%Y%m%d%H%M%S)
        subdir="u-boot-${timestamp}-${version}"
        output_file="${RESULT_OUTPUT}/${subdir}.tar.bz2" # 设置输出文件名

        # 3. 打包压缩文件
        echo -e "${INFO}▶ 正在打包文件到 ${output_file} ..."
        #tar -cjf "${output_file}" -C "${RESULT_OUTPUT}" . # 这个文件解压后直接就是文件
        # 这个命令解压后会存在一级目录
        tar -cjf "${output_file}" \
            --exclude='*.tar.bz2' \
            --transform "s|^|${subdir}/|" \
            -C "${RESULT_OUTPUT}" .
        
        # 4. 验证压缩结果
        if [ -f "$output_file" ]; then
            echo -e "${INFO}▶ 打包成功！文件结构验证："
            tar -tjf "$output_file" # | head -n 5
            echo ""
            echo -e "${INFO}▶ 生成文件："
            ls -lh "$output_file"
        else
            cho -e "${RED}错误：文件打包失败${CLS}"
            exit 1
        fi
    )
}

function echo_menu()
{
    echo "================================================="
	echo -e "${GREEN}               build project ${CLS}"
	echo -e "${GREEN}                by @苏木    ${CLS}"
	echo "================================================="
    echo -e "${PINK}current path         :$(pwd)${CLS}"
    echo -e "${PINK}PROJECT_ROOT         :${PROJECT_ROOT}${CLS}"
    echo -e "${PINK}ARCH_NAME            :${ARCH_NAME}${CLS}"
    echo -e "${PINK}CROSS_COMPILE_NAME   :${CROSS_COMPILE_NAME}${CLS}"
    echo -e "${PINK}BOARD_DEFCONFIG      :${BOARD_NAME} ${BOARD_DEFCONFIG}${CLS}"
    echo -e "${PINK}COMPILE_PLATFORM     :${COMPILE_PLATFORM}${CLS}"
    echo ""
    echo -e "* [0] 编译 U-Boot 源码"
    echo -e "* [1] 清理 U-Boot 工程"
    echo -e "* [2] 下载成果物到SD卡"
    echo -e "* [3] 打包成果物文件和配置文件"
    echo -e "* [4] githubaction编译、打包、发布"
    echo -e "* [5] 查看脚本使用说明"
    echo "================================================="
}

function func_process()
{
	# read -p "请选择功能,默认选择0:" choose
    #read -t 3 -p "请选择功能(3s后超时自动执行),默认选择0,超时选择3:" choose
    if [ ${COMPILE_PLATFORM} == 'githubaction' ];then
    choose=4
    else
    read -p "请选择功能,默认选择0:" choose
    fi
	case "${choose}" in
		"0") 
            uboot_build ${BOARD_NAME} ${BOARD_DEFCONFIG}
            download_imx2sd
            download_imx2tftp
            ;;
		"1") uboot_project_clean 1;;
        "2") download_imx2sd;;
        "3") 
            uboot_savedefconfig
            update_result_file
            ;;
        "4") 
            source_env_info
            arm_gcc_check
            uboot_build ${BOARD_NAME} ${BOARD_DEFCONFIG}
            uboot_savedefconfig
            update_result_file
            ;;
        "5")usage;;
		*) 
            uboot_build ${BOARD_NAME} ${BOARD_DEFCONFIG}
            download_imx2sd
            download_imx2tftp
            ;;
	esac
}

echo_menu
func_process

# 命令总结
# ========================================================
# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean  # 清除生成的所有文件
# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean      # 清除部分文件

# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- mx6ull_14x14_evk_defconfig
# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- mx6ull_alpha_emmc_defconfig
# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- savedefconfig

# make V=0 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j16
# sudo dd if=u-boot-dtb.imx of=/dev/sdc bs=1k seek=1 conv=fsync