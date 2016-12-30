#! /usr/bin/env python3

import argparse
from datetime import datetime
import subprocess as sub
import sys

class Time:
    def __init__(self, dt):
        self.hour = dt.hour
        self.minute = dt.minute
        self.second = dt.second
        self.month = dt.month
        self.day = dt.day
        self.year = dt.year

    def encode(self):
        return '{hh}:{mm}:{ss} {YYYY}-{MM}-{DD}'.format(
            hh=self.hour,
            mm=self.minute,
            ss=self.second,
            MM=self.month,
            DD=self.day,
            YYYY=self.year
        )

def subprocess(argv):
    p = sub.Popen(argv, stdout=sub.PIPE,stderr=sub.PIPE)
    stdout, stderr = p.communicate()
    if p.returncode != 0:
        print(stderr.decode('utf-8'), end='', file=sys.stderr)
        sys.exit(p.returncode)
    else:
        return stdout.decode('utf-8')

def main():
    parser = argparse.ArgumentParser(description='View and set the system time.')
    parser.add_argument('--hour', action='store', type=int)
    parser.add_argument('--minute', action='store', type=int)
    parser.add_argument('--second', action='store', type=int)
    parser.add_argument('--month', action='store', type=int)
    parser.add_argument('--day', action='store', type=int)
    parser.add_argument('--year', action='store', type=int)
    parser.add_argument('--hardware', action='store_true')

    args = parser.parse_args()
    time = Time(datetime.now())
    set_time = False

    def set_field(field):
        nonlocal set_time
        if hasattr(args, field) and getattr(args, field):
            set_time = True
            setattr(time, field, getattr(args, field))

    [set_field(field) for field in ['hour', 'minute', 'second', 'month', 'day', 'year']]

    process = ['date', '--set', time.encode()] if set_time else ['date']
    print(subprocess(process), end='')

    if args.hardware:
        subprocess(['hwclock'])


if __name__ == '__main__':
    main()
