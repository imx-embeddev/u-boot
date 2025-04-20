#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : git_config.sh
# * Author     : 苏木
# * Date       : 2025-04-19
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
# git url 配置
# ========================================================
# 这样一个git push -u origin master 就可以推送两个仓库了，但是需要注意，分支名必须相同
# 定义必须存在的 URL 列表
required_urls=(
    "git@github.com:imx-embeddev/u-boot.git"
    "git@gitee.com:sumumm/u-boot.git"
)

remote_name="origin" # 获取当前远程名称（默认为origin）

# 检查是否在 Git 仓库中
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "${RED}错误：当前目录不是 Git 仓库！${CLS}"
    exit 1
fi

# 获取当前配置的所有 URL
existing_urls=$(git config --get-all remote.origin.url)
echo -e "${INFO}▶ 开始检查远程 URL 配置..."

# 检查每个必须存在的 URL
# 遍历检查每个必要URL
for url in "${required_urls[@]}"; do
    if printf '%s\n' "${existing_urls[@]}" | grep -Fxq "$url"; then
        echo -e "${GREEN}✓ URL已存在: ${url}${CLS}"
    else
        echo -e "${YELLOW}⚠ 添加缺失URL: ${url}${CLS}"
        if git remote set-url --add "$remote_name" "$url"; then
            echo -e "${GREEN}  添加成功${CLS}"
        else
            echo -e "${RED}  添加失败${CLS}"
        fi
    fi
done

# 显示最终验证结果
echo -e "\n${BLUE}当前远程仓库配置：${CLS}"
git remote -v

echo -e "\n${GREEN}✅ 操作完成！${CLS}"
