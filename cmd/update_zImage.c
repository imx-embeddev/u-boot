// cmd/update.c
#include <common.h>
#include <command.h>
#include <net.h>
#include <mmc.h>

#define ZIMAGE_IMG_ADDR      0x80800000        // 内存地址，用于存放下载的镜像
#define ZIMAGE_IMG_NAME      "zImage"  // uboot名称
#define ZIMAGE_IMG_SIZE      (20 * 1024 * 1024) // 假设镜像最大4MB

static char cmd_uboot[][64] = {
    "tftp 80800000 zImage", // 从tftp服务器下载镜像666624(0xa2c00)
    "fatls mmc 0:1", // 查看sd卡分区1中的文件，fat32格式才行
    "fatwrite mmc 0:1 80800000 zImage 6788f8", // 写入zImage
};

static int do_update_zImage(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
    unsigned int i = 0;
    ulong file_len = 0;
    char *p_file_name = NULL;

    int cmd_size = sizeof(cmd_uboot[0])/sizeof(cmd_uboot[0][0]);

    // 获取镜像名称
    if(argc > 1 && argv[1] != NULL)
    {
        p_file_name = argv[1];
    }
    else 
    {
        p_file_name = ZIMAGE_IMG_NAME;
    }

    // i = 0 下载镜像：tftp 80800000 zImage
    snprintf(cmd_uboot[i], cmd_size, "tftp %x %s", ZIMAGE_IMG_ADDR, p_file_name);
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // 获取要写入的字节数
    file_len = env_get_hex("filesize", 0);
    if (!file_len) 
    {
        printf("[error]env_get_hex from filesize fail!\n");
        file_len = ZIMAGE_IMG_SIZE;//C8000=800*1024
    }
    printf("Will writing to SD card!write Bytes=%ld(0x%lx)...\n", 
            file_len, file_len);
    
    // i = 1 查看sd卡分区1的文件内容
    snprintf(cmd_uboot[i], cmd_size, "fatls mmc 0:1");
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // i = 2 写入镜像：fatwrite mmc 0:1 80800000 zImage 6788f8 # 这几个参数都是十六进制
    snprintf(cmd_uboot[i], cmd_size, "fatwrite mmc 0:1 %x %s %lx", 
                ZIMAGE_IMG_ADDR, p_file_name, file_len);
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
    update_zImage, 2, 0, do_update_zImage,
    "Update zImage from TFTP server",
    "\nDownload zImage via TFTP and write it to MMC/SD card\
    \nzImage load from tftp: #-->run cmd: setenv bootcmd \'tftp 80800000 /zImage\\;tftp 83000000 /imx6ull-alpha-emmc.dtb\\;bootz 80800000 - 83000000\'\
    \nzImage load from sd  : #-->run cmd: setenv bootcmd \'load mmc 0:1 0x80800000 zImage\\;tftp 83000000 /imx6ull-alpha-emmc.dtb\\;bootz 80800000 - 83000000\'"
);
