#!/usr/bin/python3
"""
Record power usage during sleep

Place in: /lib/systemd/system-sleep

"""
import os
import sys
import time

if len(sys.argv) < 3:
    # we expect at least two parameters: [pre|post] suspend
    exit()

persistent_file = '/root/energy_use.dat'
tmp_file = '/tmp/tmp_charge.dat'
bat_dir = ''.join((
    '/sys/bus/i2c/devices/0-0020/rk817-charger/power_supply/rk817-battery/'
))

charge_full_file = bat_dir + 'charge_full'
charge_full_mah = int(open(charge_full_file, 'r').readline().strip())


def get_charge():
    # unit: [mAh]
    battery_file = bat_dir + 'charge_now'
    with open(battery_file, 'r') as fid:
        charge = int(fid.read().strip())
    return charge


if sys.argv[1] == 'pre' and sys.argv[2] == 'suspend':
    print('pre suspend')
    charge = get_charge()
    current_time = time.time()
    with open(tmp_file, 'w') as fid:
        fid.write('{}\n{}\n'.format(current_time, charge))

elif sys.argv[1] == 'post' and sys.argv[2] == 'suspend':
    print('post suspend')
    if not os.path.isfile(tmp_file):
        # do nothing if we did not record the time/charge before suspend
        exit()
    charge = get_charge()
    current_time = time.time()
    with open(tmp_file, 'r') as fid:
        old_time = float(fid.readline().strip())
        old_charge = int(fid.readline().strip())
    # [s]
    diff_time = current_time - old_time
    diff_charge = old_charge - charge
    print('times', old_time, current_time)
    print('charges', old_charge, charge)
    print('diffs:', diff_time, diff_charge)

    # compute the sleep energy usage / day in units of full capacity
    energy_per_day = diff_charge / diff_time * 3600 * 24 / charge_full_mah

    print('energy per day:', energy_per_day)

    os.unlink(tmp_file)

    if not os.path.isfile(persistent_file):
        open(persistent_file, 'w').write(
            '{}, {}, {}\n'.format(
                'time[s]',
                'bat[mAh]',
                'use_per_day',
            )
        )

    with open(persistent_file, 'a') as fid:
        fid.write(
            '{:.2f}, {:.3f}, {:.3f}\n'.format(
                diff_time, diff_charge, energy_per_day
            )
        )
