#!/usr/bin/env python
# parsed block output of parted print and generates an mtdparts line for use with rkdeveloptool write-partition-table
# make sure to switch parted to sector output using the "u s" switch
import pandas as pd
df = pd.read_csv('partition_table.dat', delim_whitespace=True)
df['Start'].apply(hex)
df['start_hex'] = df['Start'].apply(hex)
df['size_hex'] = df['Size'].apply(hex)

mtdparts = 'mtdparts=rk3566mmc:'
for index, (nr, partition) in enumerate(df.iterrows()):
    # print(partition)
    pstr = '{}@{}({})'.format(partition['size_hex'], partition['start_hex'], partition['Name'])
    print(index, nr, pstr)
    mtdparts += pstr + ','
mtdparts = mtdparts[:-1]
print(mtdparts)
