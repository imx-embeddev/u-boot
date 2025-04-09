// cmd/update.c
#include <common.h>
#include <command.h>
#include <linux/compiler.h>

DECLARE_GLOBAL_DATA_PTR;

static char cmd_uboot[8][64] = {
    "bdinfo",     // 查看设备树的地址 fdt_blob
    "fdt addr 0x9ef3edf0",
    "fdt header",
    "fdt print /chosen",
};

static int do_dtb_info(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
    unsigned int i = 0;
    int cmd_size = sizeof(cmd_uboot[0])/sizeof(cmd_uboot[0][0]);

    // i = 0 查看一些信息，包括设备树地址：bdinfo
    snprintf(cmd_uboot[i], cmd_size, "bdinfo");
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // i = 1 配置fdt的addr参数: fdt addr 0x9ef3edf0
    printf("uboot dtb addr = 0x%lx\n", (ulong)gd->fdt_blob);
    snprintf(cmd_uboot[i], cmd_size, "fdt addr 0x%lx", (ulong)gd->fdt_blob);
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // i = 2 查看设备树头的信息：fdt header
    snprintf(cmd_uboot[i], cmd_size, "fdt header");
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // i = 3 查看chosen节点信息：fdt print /chosen
    snprintf(cmd_uboot[i], cmd_size, "fdt print /chosen");
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

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
    dtb_info, 1, 0, do_dtb_info,
    "View uboot device tree information",
    "\nSet the devicetree address of the fdt command to view the uboot device tree information"
);
