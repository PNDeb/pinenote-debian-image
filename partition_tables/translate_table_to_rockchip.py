#!/usr/bin/env python

import pandas as pd
df = pd.read_csv(
    'table_standard1.txt',
    delim_whitespace=True,
    comment='#', names=['start', 'size', 'label', 'bootable']
)
final_sector = 0
part_str = 'mtdparts=rk3566mmc:'
for index, (start, size, label, bootable) in df.iterrows():
    if start == 'C':
        start = final_sector

    else:
        start = int(start, 16)
    flag = ''
    if size == 'grow':
        size = '-'
        flag = ':grow'
    else:
        size = int(size, 16)
        final_sector = start + size
        size = '{}'.format(hex(size))

    if bootable:
        assert flag == '', \
            'this script does not support flags bootable AND grow'
        flag = ':bootable'

    part_str += '{}@{}({}{}),'.format(
        size,
        hex(start),
        label,
        flag
    )

part_str = part_str[:-1]
print(part_str)
