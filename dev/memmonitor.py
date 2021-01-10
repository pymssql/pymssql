# -*- coding: utf-8 -*-
#!/usr/bin/python
"""
Print memory usage for pid.
"""

import sys
from subprocess import Popen, PIPE

def fsize(fsize_b):
    """
    Formats the bytes value into a string with KiB, MiB or GiB units

    :param fsize_b: the filesize in bytes
    :type fsize_b: int
    :returns: formatted string in KiB, MiB or GiB units
    :rtype: string

    **Usage**

    >>> fsize(112245)
    '109.6 KiB'

    """
    fsize_kb = fsize_b / 1024.0
    if fsize_kb < 1024:
        return "%.1f KiB" % fsize_kb
    fsize_mb = fsize_kb / 1024.0
    if fsize_mb < 1024:
        return "%.1f MiB" % fsize_mb
    fsize_gb = fsize_mb / 1024.0
    return "%.1f GiB" % fsize_gb

pid = sys.argv[1]
p = Popen(['ps', 'ufp', pid], stdout=PIPE, stdin=PIPE)
p.wait()
(vss, rss) = map(int, p.stdout.read().splitlines()[-1].split()[4:6])
print('VSS: %-8s (%s)' % (fsize(vss), vss))
print('RSS: %-8s (%s)' % (fsize(rss), rss))
