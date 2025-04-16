#!/bin/bash
# * =====================================================
# * Copyright © hk. 2022-2025. All rights reserved.
# * File name  : setup_env.sh
# * Author     : 苏木
# * Date       : 2025-04-03
# * ======================================================
##

# ========================================
# 需要检查的软件包列表
basic_packages=(git gcc make g++ gzip bzip2 tar wget)
kernel_required_packages=(lzop libncurses5-dev)
buildroot_required_packages=(sed make binutils build-essential gcc g++ bash patch gzip bzip2 
                             perl tar cpio unzip rsync file bc wget g++-multilib)


# 通用数组合并函数
function merge_arrays() 
{
    local mode=$1  # 合并模式：all-保留所有，unique-去重，sorted-排序去重
    # 位置参数可以用shift命令左移。
    # 比如shift 3表示原来的$4现在变成$1，原来的$5现在变成$2等等，原来的$1、$2、$3丢弃，$0不移动。
    # 不带参数的shift命令相当于shift 1。
    shift  # 获取所有数组名,

    # 合并所有数组元素
    local combined=()
    for arr_name in "$@"; do
        local -n arr_ref=${arr_name}  # 使用nameref引用数组
        combined+=("${arr_ref[@]}")
    done

    # 处理不同模式
    case $mode in
        "all")
            echo "${combined[@]}"
            ;;
        "unique")
            declare -A seen
            local unique=()
            for item in "${combined[@]}"; do
                [[ ! -v seen[$item] ]] && {
                    unique+=("$item")
                    seen[$item]=1
                }
            done
            echo "${unique[@]}"
            ;;
        "sorted")
            printf "%s\n" "${combined[@]}" | sort -u | xargs
            ;;
        *)
            echo "错误：未知模式 '${mode}'" >&2
            return 1
            ;;
    esac
}
required_packages=($(merge_arrays unique basic_packages kernel_required_packages buildroot_required_packages))
echo "required_packages: ${required_packages[*]}"

# ========================================
missing_packages=()
# 检查软件包是否已安装
for pkg in "${required_packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        missing_packages+=("$pkg")
    fi
done

# ========================================
# 如果所有软件包都已安装则直接退出
if [ ${#missing_packages[@]} -eq 0 ]; then
    echo "所有必需软件包已安装"
    exit 0
fi

# 安装缺失的软件包
echo "正在安装缺失的软件包：${missing_packages[*]}"
apt-get update && apt-get install -y "${missing_packages[@]}"

# 检查安装结果
if [ $? -eq 0 ]; then
    echo "软件包安装成功"
else
    echo "软件包安装失败" >&2
    exit 1
fi