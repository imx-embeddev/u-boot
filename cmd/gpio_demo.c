/*
 * Control GPIO pins on the fly
 *
 * Copyright (c) 2008-2011 Analog Devices Inc.
 *
 * Licensed under the GPL-2 or later.
 */

#include <common.h>
#include <command.h>

static int do_gpio_demo(cmd_tbl_t *cmdtp, int flag, int argc, char * const argv[])
{
	int i = 0;
    printf("hello gpio_demo!argc=%d flag=%d\n", argc, flag);
    printf("\tcmdtp->name=%s\n", cmdtp->name);
    printf("\tcmdtp->maxargs=%d\n", cmdtp->maxargs);
    printf("\tcmdtp->usage=%s\n", cmdtp->usage);
    printf("\tcmdtp->help=%s\n", cmdtp->help);
    printf("\n");
    for(i = 0; i < argc; i++)
    {
        printf("[%s][%d]argv[%d]=%s\n", __FUNCTION__, __LINE__, i, argv[i]);
    }
	return 0;
}

U_BOOT_CMD(gpio_demo, 4, 0, do_gpio_demo,
	   "sumu gpio_demo",
	   "print args");
