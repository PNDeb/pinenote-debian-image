#!/usr/bin/env python
# pip install pypng
import png
import array


def convert_to_pn(infile, outfile):
    # assumes that the png is 1872 x 1404, 8-bit grayscal
    reader = png.Reader(infile)
    width, height, values, info = reader.read_flat()
    # data = map(lambda x: map(int, x/17), values)
    out_array = array.array('b')
    out_array.fromlist([int(x / 17) for x in values])
    image_4bit = []
    for i in range(0, len(out_array), 2):
        image_4bit += [out_array[i] << 4 | out_array[i + 1]]
    with open(outfile, 'wb') as fid:
        fid.write(bytes(image_4bit))
    assert len(image_4bit) == 1314144, "wrong output size!"


if __name__ == '__main__':
    convert_to_pn('pine64_grayscale.png', 'pine64.bin')
