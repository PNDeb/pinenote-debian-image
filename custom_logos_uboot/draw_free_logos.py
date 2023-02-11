#!/usr/bin/env python
# import png
# import PIL
import os
import shutil
import subprocess
from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont


def generate_battery_logos(outdir):
    background_empty = Image.open('pine_empty_sheet_rotated.png')

    pen = ImageDraw.Draw(background_empty)

    startx = 400
    endx = 1000
    starty = 200
    endy = 1000

    pen.rounded_rectangle(
        [
            (400, 200),
            (1000, 1000),
        ],
        radius=30,
        outline=0,
        fill=255,
        width=10,
    )

    pen.rounded_rectangle(
        [
            (startx + (endx - startx) / 2 - 70, starty - 100),
            (startx + (endx - startx) / 2 + 70, starty + 10),
        ],
        radius=30,
        outline=0,
        fill=255,
        width=10,
    )

    battery_warning = background_empty.copy()
    font_title = ImageFont.truetype('FreeMono.ttf', 65)

    pen.text(
        (300, endy + 100),
        'PineNote is charging!',
        font=font_title,
        fill=0,
    )

    nr_bars = 5
    stepy = (endy - starty) / (nr_bars * 3)

    for i in range(-1, 5):
        if i >= 0:
            pen.line(
                [
                    (startx + 50, endy - (2.5 + (i + 0) * 2.5) * stepy),
                    (endx - 50, endy - (2.5 + (i + 0) * 2.5) * stepy),
                ],
                width=int(2 * stepy)
            )

        image = background_empty.rotate(-90, expand=True)
        # just for testing because I do like non-rotated images...
        # image = background.copy()
        filename = 'logo_charging_{}_raw.png'.format(i + 1)
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

    pen = ImageDraw.Draw(battery_warning)
    pen.text(
        (200, endy + 100),
        'BATTERY LOW!!! RECHARGE!!!',
        font=font_title,
        fill=0,
    )
    image = battery_warning.rotate(-90, expand=True)
    filename = 'logo_charging_lowpower_raw.png'
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


def _save_file(outbase, image_raw):
    save1 = outbase + '_raw.png'
    save2 = outbase + '.png'
    image = image_raw.rotate(-90, expand=True)
    image.save(save1)

    cmd = ''.join((
        'convert ',
        save1,
        ' ',
        '-depth 4 -colorspace gray -define png:bit-depth=4 ',
        save2
    ))
    print(cmd)
    subprocess.check_output(cmd, shell=True)
    os.unlink(save1)


def generate_other_logos(outdir):
    background_empty = Image.open('pine_empty_sheet_rotated.png')

    font_title = ImageFont.truetype('FreeMono.ttf', 85)

    # logo_kernel
    logo_kernel = background_empty.copy()
    pen = ImageDraw.Draw(logo_kernel)
    pen.text(
        (300, 500),
        'PineNote',
        font=font_title,
        fill=0,
    )
    _save_file(outdir + '/logo_kernel', logo_kernel)
    _save_file(outdir + '/placeholder', logo_kernel)

    # logo_uboot
    logo_uboot = background_empty.copy()
    pen = ImageDraw.Draw(logo_uboot)
    pen.text(
        (300, 500),
        'PineNote',
        font=font_title,
        fill=0,
    )
    _save_file(outdir + '/logo_uboot', logo_uboot)

    # logo_reset
    logo_reset = background_empty.copy()
    pen = ImageDraw.Draw(logo_reset)
    pen.text(
        (300, 500),
        'PineNote',
        font=font_title,
        fill=0,
    )
    _save_file(outdir + '/logo_reset', logo_reset)

    # logo_off
    logo_off = background_empty.copy()
    pen = ImageDraw.Draw(logo_off)
    pen.text(
        (300, 500),
        'PineNote - OFF',
        font=font_title,
        fill=0,
    )
    _save_file(outdir + '/logo_off', logo_off)



if __name__ == '__main__':
    outdir = 'free_logos'
    # if os.path.isdir(outdir):
    #     shutil.rmtree(outdir)
    os.makedirs(outdir, exist_ok=True)

    generate_battery_logos(outdir)
    generate_other_logos(outdir)
