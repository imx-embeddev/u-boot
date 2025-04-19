#!/bin/bash

# ARM GCC 自动安装脚本
# 版本：2.0 (增强环境变量处理)

# 配置参数
# DOWNLOAD_URL="https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz"
DOWNLOAD_URL="https://mirrors.dotsrc.org/armbian-dl/_toolchain/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz"
INSTALL_DIR="$HOME/2software/arm-gcc"
TAR_FILE="${DOWNLOAD_URL##*/}"
TOOLCHAIN_PATH="$INSTALL_DIR/arm-gcc-binaries/bin"
PROFILE_FILES=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.profile"
    "$HOME/.zshrc"
    "/etc/profile"
    "/etc/bash.bashrc"
    "/etc/zsh/zshrc"
)

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 错误处理函数
function error_exit() 
{
    echo -e "${RED}[错误] $1${RESET}" >&2
    exit 1
}

# 检查命令是否存在
function check_command() 
{
    if ! command -v "$1" &> /dev/null; then
        error_exit "未找到必要命令：$1，请先安装"
    fi
}

# 创建安装目录
function create_dir() 
{
    echo -e "${BLUE}➤ 创建安装目录：${INSTALL_DIR}${RESET}"
    mkdir -p "$INSTALL_DIR" || error_exit "目录创建失败"
}

# 下载工具链
function download_toolchain() 
{
    echo -e "${BLUE}➤ 开始下载 ARM GCC 工具链...${RESET}"
    if [ ! -f "$TAR_FILE" ]; then
        wget --show-progress --progress=bar:force:noscroll "$DOWNLOAD_URL" || error_exit "下载失败"
    else
        echo -e "${YELLOW}检测到已存在下载文件，跳过下载${RESET}"
    fi
}

# 解压工具链
function extract_toolchain() 
{
    echo -e "${BLUE}➤ 解压工具链文件...${RESET}"
    if [ ! -d "$INSTALL_DIR/arm-gcc-binaries" ]; then
        tar -xJf "$TAR_FILE" -C "$INSTALL_DIR" || error_exit "解压失败"
        mv "$INSTALL_DIR/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf" "$INSTALL_DIR/arm-gcc-binaries" || error_exit "目录重命名失败"
    else
        echo -e "${YELLOW}检测到已存在工具链文件，跳过解压${RESET}"
    fi
}

# 更新环境变量
function update_env() 
{
    local path_line="export PATH=\"$TOOLCHAIN_PATH:\$PATH\""
    
    echo -e "${BLUE}➤ 更新环境变量配置...${RESET}"
    
    for profile in "${PROFILE_FILES[@]}"; do
        # 跳过不存在的配置文件
        [ -f "$profile" ] || continue
        
        # 检查是否已经配置
        if ! grep -qF "$path_line" "$profile"; then
            echo -e "${GREEN}更新文件: ${profile}${RESET}"
            echo -e "\n# ARM GCC Toolchain\n$path_line" | tee -a "$profile" > /dev/null
        else
            echo -e "${YELLOW}已存在配置: ${profile}${RESET}"
        fi
    done
}

# 验证安装
function verify_installation() 
{
    echo -e "${BLUE}➤ 刷新环境变量...${RESET}"
    # 尝试自动加载配置
    source "$HOME/.bashrc" 2>/dev/null || true
    source /etc/profile 2>/dev/null || true

    echo -e "${BLUE}➤ 验证工具链安装...${RESET}"
    if arm-linux-gnueabihf-gcc --version &> /dev/null; then
        echo -e "${GREEN}✅ 验证成功！工具链版本信息：${RESET}"
        arm-linux-gnueabihf-gcc --version | head -n1
    else
        echo -e "${RED}工具链验证失败，请手动执行以下命令：${RESET}"
        echo "source ~/.bashrc 或重新打开终端"
        exit 1
    fi
}

# 主流程
function main() 
{
    # 检查必要命令
    check_command wget
    check_command tar

    # 执行安装流程
    create_dir
    cd "$INSTALL_DIR" || error_exit "无法进入安装目录"
    download_toolchain
    extract_toolchain
    update_env
    verify_installation
}

# 执行主函数
main
