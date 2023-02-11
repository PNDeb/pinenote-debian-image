#!/usr/bin/env python
# import png
# import PIL
import os
import shutil
import subprocess
from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont
from PIL import ImageOps


def parse_uboot_environment():
    pass
    with open('default_env.txt', 'r') as fid:
        env = fid.readlines()
    bootmenu_entries = [line for line in env if line.startswith('bootmenu_')]
    entries = {}
    for entry in bootmenu_entries:

        index = entry.index('=')
        print(index)
        key = int(entry[9:index])
        cmd_raw = entry[index + 1:].strip()
        index_cmd = cmd_raw.index('=')
        key_cmd = cmd_raw[0:index_cmd].strip()
        cmd = cmd_raw[index_cmd + 1:].strip()

        entries[key] = (key_cmd, cmd)
    print(entries)
    return entries

    # import IPython
    # IPython.embed()


def render_bootmenu_logos(uboot_entries):
    outdir = 'logos_bootmenu'
    if os.path.isdir(outdir):
        shutil.rmtree(outdir)
    os.makedirs(outdir, exist_ok=True)

    background_empty = Image.open('pine_empty_sheet_rotated.png')

    debian = ImageOps.scale(
        Image.open('openlogo-100.png'),
        4,
    )

    for bootmenu_entry in range(0, 6):
        if bootmenu_entry in uboot_entries:
            (title, cmd) = uboot_entries[bootmenu_entry]
        elif bootmenu_entry == max(list(uboot_entries.keys())) + 1:
            title = 'Bootmenu entry {}'.format(
                bootmenu_entry
            )
            cmd = 'Drop to u-boot console'

        else:
            title = 'Bootmenu entry {}'.format(
                bootmenu_entry
            )
            cmd = 'no command defined'

        background = background_empty.copy()
        image = Image.new('L', (1404, 1872), 255)
        I1 = ImageDraw.Draw(background)
        font_explanation = ImageFont.truetype('FreeSerif.ttf', 30)

        I1.text(
            (50, 50),
            'Short press PWR Button to advance entries\n' +
            'Long press PWR Button to execute entry',
            font=font_explanation,
            fill=0,
        )

        font_size = 65
        font_title = ImageFont.truetype('FreeMono.ttf', font_size)
        text_width = None
        while font_size > 20 and (text_width is None or text_width > 1404 - 50):
            font_size -= 5
            font_title = ImageFont.truetype('FreeMono.ttf', font_size)
            bbox = font_title.getbbox(title)
            print('bbox', bbox, font_size)
            text_width = bbox[2]
        I1.text(
            (50, 600),
            title,
            font=font_title,
            fill=0
        )

        font_size = 45
        font_cmd = ImageFont.truetype('FreeMono.ttf', 40)
        text_width = None
        while font_size > 20 and (text_width is None or text_width > 1404 - 50):
            font_size -= 5
            font_cmd = ImageFont.truetype('FreeMono.ttf', font_size)
            # import IPython
            # IPython.embed()
            bbox = font_cmd.getbbox(
                cmd,
            )
            print('bbox', bbox, font_size)
            text_width = bbox[2]

        I1.text(
            (50, 900),
            cmd,
            font=font_cmd,
            fill=0
        )

        if cmd.startswith('sysboot'):
            background.paste(debian, (900, 50))

        image = background.rotate(-90, expand=True)
        # just for testing because I do like non-rotated images...
        # image = background.copy()
        filename = 'logo_bootmenu_{}_raw.png'.format(bootmenu_entry + 1)
        image.save(
            outdir + os.sep + filename
        )

        cmd = ''.join((
            'convert ',
            outdir + os.sep + filename,
            ' ',
            '-depth 4 -colorspace gray -define png:bit-depth=4 ',
            outdir + os.sep + filename[0:-8] + '.png',
        ))
        print(cmd)
        subprocess.check_output(cmd, shell=True)
        os.unlink(outdir + os.sep + filename)


if __name__ == '__main__':
    uboot_entries = parse_uboot_environment()
    render_bootmenu_logos(uboot_entries)
