// cmd/update.c
#include <common.h>
#include <command.h>

static char cmd_uboot[][256] = {
    // 配置ip

    "setenv ipaddr 192.168.10.102",      // 开发板 IP 地址
    // "setenv ethaddr 00:04:9f:04:d2:35",    // 开发板网卡 MAC 地址 b8:ae:1d:01:00:00,之前是要配置这个，现在好像用下面的就行了
    "setenv eth1addr 32:34:46:78:9A:DD", // 开发板网卡 MAC 地址
    "setenv gatewayip 192.168.10.1",     // 开发板默认网关
    "setenv netmask 255.255.255.0",      // 开发板子网掩码
    "setenv serverip 192.168.10.101",    // 服务器地址，也就是 Ubuntu 地址

    // 配置bootargs
    "setenv bootargs \'console=ttymxc0,115200 root=/dev/nfs nfsroot=192.168.10.101:/home/sumu/4nfs/imx6ull_rootfs,proto=tcp rw ip=192.168.10.102:192.168.10.101:192.168.10.1:255.255.255.0::eth0:off init=/linuxrc\'",
    "setenv bootcmd \'tftp 80800000 /zImage\\;tftp 83000000 /imx6ull-alpha-emmc.dtb\\;bootz 80800000 - 83000000\'",
    "print ipaddr gatewayip netmask serverip bootargs bootcmd",
    "saveenv",                          // 保存环境变量
};


static int do_setup_start_param(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
    unsigned int i = 0;
    unsigned int cmd_num = sizeof(cmd_uboot)/sizeof(cmd_uboot[0]);
    char start_mmc_dev[16] = {0};

    // 获取镜像名称
    if(argc > 1 && argv[1] != NULL)
    {
        snprintf(start_mmc_dev, sizeof(start_mmc_dev), "%s", argv[1]);
    }
    else 
    {
        snprintf(start_mmc_dev, sizeof(start_mmc_dev), "%s", "tftp&nfs");
    }

    // 这里只提示，不执行，手动执行即可
    for(i = 0; i < cmd_num; i++)
    {
        // 从sd卡启动的话后后面要修改参数
        if(i == 5 && !strcmp (start_mmc_dev, "sd"))
        {
            snprintf(cmd_uboot[i], sizeof(cmd_uboot[i]), "%s", \
                "setenv bootargs \'console=ttymxc0,115200 root=/dev/mmcblk0p2 ip=192.168.10.102:192.168.10.101:192.168.10.1:255.255.255.0::eth0:off init=/linuxrc\'");
        }
        else if (i == 6 && !strcmp (start_mmc_dev, "sd"))
        {
            snprintf(cmd_uboot[i], sizeof(cmd_uboot[i]), "%s", \
                "setenv bootcmd \'mmc dev 0\\;fatload mmc 0:1 80800000 zImage\\;fatload mmc 0:1 83000000 imx6ull-alpha-emmc.dtb\\;bootz 80800000 - 83000000\'");
        }
        printf("#-->run cmd: %s\n", cmd_uboot[i]);
        run_command(cmd_uboot[i], 0);
    }
    return 0;
}

/**
 * @brief  U_BOOT_CMD(name,maxargs,rep,cmd,usage,help)
 * @note   
 * @param  [in] name	命令的名称，此处直接输入即可，不要用字符串"xxx"的形式
 * @param  [in] maxargs	命令的最大参数个数，至少为1，表示命令本身
 * @param  [in] rep	    是否自动重复（为1的话下次直接按Enter键会重复执行此命令）
 * @param  [in] cmd	    命令对应的响应函数，即之前的do_mycmd()函数，直接使用函数名
 * @param  [in] usage	简短的使用说明（字符串）
 * @param  [in] help	输入help后显示的较详细的帮助文档（字符串）,help xxx
 * @param  [out]
 * @retval 
 */
U_BOOT_CMD(
    setup_start_param, 2, 0, do_setup_start_param,
    "set ip & bootargs",
    "\nDownload the kernel image through tftp and mount the root file system through nfs"
);
