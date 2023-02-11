/*
 * Downloaded and modified from
 * https://github.com/DorianRudolph/pinenotes/tree/main/logodump
 * (at commit 4a8bf7ae21d31b2372eb1df13ffc48523c9edfcb)
 *
 * (C) Copyright 2023 Maximilian Weigand
 *
 * SPDX-License-Identifier:     GPL-2.0+
 *
 * Based on work with copyright:
 * (C) Copyright 2021 Dorian Rudolph
 *
 * SPDX-License-Identifier:     GPL-2.0+
 *
 * Based on work with copyright:
 * * (C) Copyright 2020 Rockchip Electronics Co., Ltd
 * *
 * * SPDX-License-Identifier:     GPL-2.0+
 * * Author: Wenping Zhang <wenping.zhang@rock-chips.com>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <png.h>

#define LOGO_IMG_SIZE 0x2000000
#define SCREEN_WIDTH 1872
#define SCREEN_HEIGHT 1404
#define LOGO_SIZE SCREEN_WIDTH * SCREEN_HEIGHT / 2
#define LOGO_COUNT 18
#define COLOR_BITS 4

#define ASSERTF(a, fmt, ...) do { if(!(a)) { fprintf(stderr, fmt, ##__VA_ARGS__); exit(1); } } while(0)

enum type_logo {
	EINK_LOGO_RESET = 0,
	EINK_LOGO_UBOOT = 1 << 0,
	EINK_LOGO_KERNEL = 1 << 1,
	EINK_LOGO_CHARGING_0 = 1 << 2,
	EINK_LOGO_CHARGING_1 = 1 << 3,
	EINK_LOGO_CHARGING_2 = 1 << 4,
	EINK_LOGO_CHARGING_3 = 1 << 5,
	EINK_LOGO_CHARGING_4 = 1 << 6,
	EINK_LOGO_CHARGING_5 = 1 << 7,
	EINK_LOGO_CHARGING_LOWPOWER = 1 << 8,
	EINK_LOGO_POWEROFF = 1 << 9,
	EINK_LOGO_UNMIRROR_TEMP_BUF = 1 << 10,
	EINK_BOOTMENU_1 = 1 << 11,
	EINK_BOOTMENU_2 = 1 << 12,
	EINK_BOOTMENU_3 = 1 << 13,
	EINK_BOOTMENU_4 = 1 << 14,
	EINK_BOOTMENU_5 = 1 << 15,
	EINK_BOOTMENU_6 = 1 << 16,
};

const enum type_logo USED_LOGOS[] = {
    EINK_LOGO_RESET,
    EINK_LOGO_UBOOT,
    EINK_LOGO_KERNEL,
    EINK_LOGO_CHARGING_0,
    EINK_LOGO_CHARGING_1,
    EINK_LOGO_CHARGING_2,
    EINK_LOGO_CHARGING_3,
    EINK_LOGO_CHARGING_4,
    EINK_LOGO_CHARGING_5,
    EINK_LOGO_CHARGING_LOWPOWER,
    EINK_LOGO_POWEROFF,
	EINK_LOGO_UNMIRROR_TEMP_BUF,  // <- this is just a place holder image
	EINK_BOOTMENU_1,
	EINK_BOOTMENU_2,
	EINK_BOOTMENU_3,
	EINK_BOOTMENU_4,
	EINK_BOOTMENU_5,
	EINK_BOOTMENU_6,
};

const char *logo_file_name(enum type_logo logo) {
  switch (logo) {
    case EINK_LOGO_RESET:
      return "logo_reset.png";
    case EINK_LOGO_UBOOT:
      return "logo_uboot.png";
    case EINK_LOGO_KERNEL:
      return "logo_kernel.png";
    case EINK_LOGO_CHARGING_0:
      return "logo_charging_0.png";
    case EINK_LOGO_CHARGING_1:
      return "logo_charging_1.png";
    case EINK_LOGO_CHARGING_2:
      return "logo_charging_2.png";
    case EINK_LOGO_CHARGING_3:
      return "logo_charging_3.png";
    case EINK_LOGO_CHARGING_4:
      return "logo_charging_4.png";
    case EINK_LOGO_CHARGING_5:
      return "logo_charging_5.png";
    case EINK_LOGO_CHARGING_LOWPOWER:
      return "logo_charging_lowpower.png";
    case EINK_LOGO_POWEROFF:
      return "logo_off.png";
	case EINK_LOGO_UNMIRROR_TEMP_BUF:
	  return "placeholder.png";
	case EINK_BOOTMENU_1:
	  return "logo_bootmenu_1.png";
	case EINK_BOOTMENU_2:
	  return "logo_bootmenu_2.png";
	case EINK_BOOTMENU_3:
	  return "logo_bootmenu_3.png";
	case EINK_BOOTMENU_4:
	  return "logo_bootmenu_4.png";
	case EINK_BOOTMENU_5:
	  return "logo_bootmenu_5.png";
	case EINK_BOOTMENU_6:
	  return "logo_bootmenu_6.png";
    default:
      ASSERTF(0, "Invalid logo type 0x%x.\n", logo);
  }
}

//logo partition Header, 64byte
struct logo_part_header {
  char magic[4]; /* must be "RKEL" */
  uint32_t total_size;
  uint32_t screen_width;
  uint32_t screen_height;
  uint32_t logo_count;
  char version[4];
  uint32_t rsv[10];
} __attribute__((packed));

#define PART_MAGIC "RKEL"
#define VERSION "1.00"

// logo image header,32 byte
struct grayscale_header {
  char magic[4]; /* must be "GR04" */
  uint16_t x;
  uint16_t y;
  uint16_t w;
  uint16_t h;
  uint32_t logo_type;
  uint32_t data_offset; /* image offset in byte */
  uint32_t data_size; /* image size in byte */
  uint32_t rsv[2];
} __attribute__((packed));

#define GRAYSCALE_MAGIC "GR04"

/*
 * The start address of logo image in logo.img must be aligned
 * in 512 bytes,so the header size must be times of 512 bytes.
 * Here we fix the size to 512 bytes, so the count of logo image
 * can only support up to 14.
 *
 */
struct logo_info {
  struct logo_part_header part_hdr;
  struct grayscale_header img_hdr[30];
} __attribute__((packed));

void *read_file(const char *path, size_t *sz) {
  FILE *fp = fopen(path, "rb");
  ASSERTF(fp, "Error opening file \"%s\": %s\n", path, strerror(errno));
  fseek(fp, 0, SEEK_END);
  *sz = ftell(fp);
  fseek(fp, 0, SEEK_SET);
  char *buf = malloc(*sz);
  size_t r = fread(buf, 1, *sz, fp);
  ASSERTF(r == *sz, "Could not read file \"%s\" completely.\n", path);
  fclose(fp);
  return buf;
}

void write_file(const char *path, const void *buf, size_t sz) {
  FILE *fp = fopen(path, "wb");
  ASSERTF(fp, "Error opening file \"%s\": %s\n", path, strerror(errno));
  size_t w = fwrite(buf, 1, sz, fp);
  ASSERTF(w == sz, "Could not read file \"%s\" completely.\n", path);
  fclose(fp);
}


void write_png(char *path, uint32_t w, uint32_t h, unsigned char *buf) {
  FILE *fp = fopen(path, "wb");
  ASSERTF(fp, "Error opening file \"%s\" for writing: %s\n", path, strerror(errno));

  png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  ASSERTF(png, "Failed to create PNG write struct.");

  png_infop info = png_create_info_struct(png);
  ASSERTF(png, "Failed to create info struct.");

  if (setjmp(png_jmpbuf(png)))
    ASSERTF(0, "Error while creating PNG.");

  png_init_io(png, fp);

  png_set_IHDR(
      png,
      info,
      w, h,
      COLOR_BITS,
      PNG_COLOR_TYPE_GRAY,
      PNG_INTERLACE_NONE,
      PNG_COMPRESSION_TYPE_DEFAULT,
      PNG_FILTER_TYPE_DEFAULT
  );
  png_write_info(png, info);

  png_bytepp row_pointers = malloc(h * sizeof(png_bytep));
  ASSERTF(row_pointers, "malloc failed\n");
  for (int i = 0; i < h; ++i) {
    row_pointers[i] = buf + i * w / 2;
  }

  png_set_packswap(png);
  png_write_image(png, row_pointers);
  png_write_end(png, NULL);

  free(row_pointers);
  fclose(fp);

  png_destroy_write_struct(&png, &info);
}

void read_png(const char *path, uint32_t w, uint32_t h, unsigned char *buf) {
  FILE *fp = fopen(path, "rb");
  ASSERTF(fp, "Error opening file \"%s\" for reading: %s\n", path, strerror(errno));

  png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  ASSERTF(png, "Failed to create PNG read struct.");

  png_infop info = png_create_info_struct(png);
  ASSERTF(png, "Failed to create info struct.");

  if (setjmp(png_jmpbuf(png)))
    ASSERTF(0, "Error while creating PNG.");

  png_init_io(png, fp);

  png_read_info(png, info);

  uint32_t width = png_get_image_width(png, info);
  ASSERTF(width == w, "Expected width %u but got %u.\n", w, width);
  uint32_t height = png_get_image_height(png, info);
  ASSERTF(height == h, "Expected height %u but got %u.\n", h, height);
  uint32_t color_type = png_get_color_type(png, info);
  ASSERTF(color_type == PNG_COLOR_TYPE_GRAY, "Expected grayscale.\n");
  uint32_t bit_depth = png_get_bit_depth(png, info);
  ASSERTF(bit_depth == COLOR_BITS, "Expected %d bit color depth.\n", COLOR_BITS);

  png_set_packswap(png);
  png_read_update_info(png, info);

  png_bytepp row_pointers = malloc(sizeof(png_bytep) * height);
  uint32_t rowbytes = width / 2;
  ASSERTF(png_get_rowbytes(png, info) == rowbytes, "Unexpected number of rowbytes\n");
  for (int i = 0; i < height; i++) {
    row_pointers[i] = buf + i * rowbytes;
  }

  png_read_image(png, row_pointers);

  fclose(fp);
  png_destroy_read_struct(&png, &info, NULL);
}

void read_logos(const char *logo_img_path, char *logos_path) {
  size_t sz;
  void *buf = read_file(logo_img_path, &sz);
  ASSERTF(sz >= sizeof(struct logo_info), "logo.img is too small.\n");
  struct logo_info *info = buf;
  ASSERTF(memcmp(info->part_hdr.magic, PART_MAGIC, 4) == 0, "logo.img has wrong magic bytes.\n");
  printf("found %u logos\n", info->part_hdr.logo_count);
  for (int i = 0; i < info->part_hdr.logo_count; ++i) {
    struct grayscale_header hdr = info->img_hdr[i];
    ASSERTF(memcmp(hdr.magic, GRAYSCALE_MAGIC, 4) == 0, "logo %d has wrong magic bytes.\n", i);
    ASSERTF(hdr.data_size + hdr.data_offset <= sz, "logo.img too small to read logo %d.\n", i);
    ASSERTF(hdr.data_size * 2 == hdr.w * hdr.h, "Logo %d size does not match its width and height.\n", i);
    char logo_path[256];
    sprintf(logo_path, "%s/%s", logos_path, logo_file_name(hdr.logo_type));
    printf("creating %s\n", logo_path);
    write_png(logo_path, hdr.w, hdr.h, buf + hdr.data_offset);
  }
  free(buf);
}

void write_logos(const char *logo_img_path, char *logos_path) {
  void *buf = calloc(LOGO_IMG_SIZE, 1);
  struct logo_info *info = buf;
  memcpy(info->part_hdr.magic, PART_MAGIC, 4);
  memcpy(info->part_hdr.version, VERSION, 4);
  info->part_hdr.logo_count = LOGO_COUNT;
  info->part_hdr.screen_height = SCREEN_HEIGHT;
  info->part_hdr.screen_width = SCREEN_WIDTH;
  uint32_t logo_offset = LOGO_SIZE;
  if (logo_offset & 0xff) logo_offset += 0x100 - (logo_offset & 0xff);
  info->part_hdr.total_size = (LOGO_COUNT - 1) * logo_offset + LOGO_SIZE + sizeof(struct logo_info);
  for (int i = 0; i < LOGO_COUNT; ++i) {
    struct grayscale_header *hdr = info->img_hdr + i;
    memcpy(hdr->magic, GRAYSCALE_MAGIC, 4);
    hdr->x = 0;
    hdr->y = 0;
    hdr->w = SCREEN_WIDTH;
    hdr->h = SCREEN_HEIGHT;
    hdr->data_size = LOGO_SIZE;
    hdr->data_offset = sizeof(struct logo_info) + i * logo_offset;
    hdr->logo_type = USED_LOGOS[i];
    char logo_path[256];
    sprintf(logo_path, "%s/%s", logos_path, logo_file_name(hdr->logo_type));
    printf("reading %s\n", logo_path);
    read_png(logo_path, hdr->w, hdr->h, buf + hdr->data_offset);
  }
  write_file(logo_img_path, buf, LOGO_IMG_SIZE);
  free(buf);
}

int main(int argc, char **argv) {
  if (argc != 4) goto usage;
  char mode = argv[1][0];
  char *logo_img_path = argv[2];
  char *logos_path = argv[3];
  if (mode == 'r') {
    read_logos(logo_img_path, logos_path);
  } else if (mode == 'w') {
    write_logos(logo_img_path, logos_path);
  } else {
    goto usage;
  }
  return 0;
  usage:
  fprintf(stderr, "Usage: %s (r|w) <logo.img> <logodir> # read/write logo.img from logos in logodir\n", *argv);
  return 1;
}
