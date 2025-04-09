// cmd/update.c
#include <common.h>
#include <command.h>
#include <net.h>
#include <mmc.h>

#define UBOOT_IMG_ADDR      0x80800000        // 内存地址，用于存放下载的镜像
#define UBOOT_IMG_NAME      "u-boot-dtb.imx"  // uboot名称
#define UBOOT_IMG_SIZE      (4 * 1024 * 1024) // 假设镜像最大4MB
#define SDCARD_START_SECTOR (0x2)               // 从sd卡第2个扇区开始写，就是1KB的位置

static char cmd_uboot[][64] = {
    "tftp 80800000 u-boot-dtb.imx",// 从tftp服务器下载镜像666624(0xa2c00)
    "mmc dev 0 0", //切换到sd卡0分区
    "mmc write 80800000 2 516",// 512=1302(扇区)=0x516，这里要从1KB的地方开始写，就是第2个扇区
};

// 仅当 `alignment` 是 2 的幂次时可用（如 4, 8, 16, 512）
unsigned int align_up_power2(unsigned int x, unsigned int alignment) 
{
    return (x + alignment - 1) & ~(alignment - 1);
}
// 示例：align_up_power2(1234, 512) → 1536

static int do_update_uboot(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
    unsigned int i = 0;
    ulong file_len = 0;
    
    struct blk_desc *desc = NULL;
    lbaint_t blk_count = 0;

    int cmd_size = sizeof(cmd_uboot[0])/sizeof(cmd_uboot[0][0]);

    // i = 0 下载镜像：tftp 80800000 u-boot-dtb.imx
    snprintf(cmd_uboot[i], cmd_size, "tftp %x %s", UBOOT_IMG_ADDR, UBOOT_IMG_NAME);
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // 获取一些sd卡信息,计算要写入的扇区数量
    struct mmc *mmc = find_mmc_device(0);
    if (!mmc) 
    {
        printf("MMC device 0 not found\n");
        return CMD_RET_FAILURE;
    }

    desc = blk_get_devnum_by_typename("mmc", 0); // 获取扇区信息
    if (!desc) 
    {
        printf("Failed to get block device\n");
        return CMD_RET_FAILURE;
    }

    file_len = env_get_hex("filesize", 0);
    if (!file_len) 
    {
        printf("[error]env_get_hex from filesize fail!\n");
        file_len = 0xC8000;//C8000=800*1024
    }
    blk_count = (file_len + desc->blksz - 1) / desc->blksz; // 一共要写入的扇区数
    //blk_count = align_up_power2(file_len, 512)/512; // 计算对齐后的文件大小,这里就是扇区数量了
    if (SDCARD_START_SECTOR + blk_count > desc->lba) 
    {
        printf("Error: Not enough space on MMC\n");
        return CMD_RET_FAILURE;
    }
    
    printf("Will writing to SD card!write infoblock=%d(0x%x), count=%lu(0x%lx), sd card info:lba=%ld blksz=%ld ...\n", 
            SDCARD_START_SECTOR, SDCARD_START_SECTOR, blk_count, blk_count, desc->lba, desc->blksz);

    // i = 1 切换到sd卡：mmc dev 0 0
    snprintf(cmd_uboot[i], cmd_size, "mmc dev 0 0");
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);
    i++;

    // i = 2 写入镜像：mmc write 80800000 2 516 # 这几个参数都是十六进制
    snprintf(cmd_uboot[i], cmd_size, "mmc write %x %x %lx", 
                UBOOT_IMG_ADDR, SDCARD_START_SECTOR, blk_count);
    printf("#--->run cmd:%s\n", cmd_uboot[i]);
    run_command(cmd_uboot[i], 0);

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
    update_uboot, 1, 0, do_update_uboot,
    "Update U-Boot from TFTP server",
    "\nDownload u-boot.img via TFTP and write it to MMC/SD card"
);
