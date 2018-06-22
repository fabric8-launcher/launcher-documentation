#!/usr/bin/python3

import os
from re import match, fullmatch
import sys
import tempfile
import subprocess

LINE_PATTERN = '^=+ .*[A-Z].*[A-Z].*$'
WORD_PATTERN = '[A-Z][a-z-]*'
SKIPPED = ['Git', 'Red', 'Hat', 'Jolokia', 'Agroal', 'Developer', 'Studio', 'Nodeshift', 'Hystrix', 'Netty']

def convert(string):
    first = True
    converted = []
    for token in string.split():
        if fullmatch(WORD_PATTERN, token) and not first and token not in SKIPPED:
            converted.append(token.lower())
        else:
            converted.append(token)
        if not token.startswith('='):
            first = False
    return ' '.join(converted) + '\n'


def process_file(filename):
    if os.path.isdir(os.path.realpath(filename)):
        print('{} is a directory, skipping'.format(filename))
        return

    if not os.path.isfile(os.path.realpath(filename)):
        print('{} is not a file, skipping'.format(filename))
        return

    temp_filename = tempfile.mkstemp()[1]
    with open(temp_filename, 'w') as tf:
        with open(filename, 'r') as f:
            for l in f.readlines():
                if match(LINE_PATTERN, l):
                    tf.write(convert(l))
                else:
                    tf.write(l)
    subprocess.check_call(['cp', temp_filename, os.path.realpath(filename)])
    os.unlink(temp_filename)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: sentence_case.py FILE1 [FILE2 [FILE3 ...]]')
        sys.exit(1)

    for f in sys.argv[1:]:
        process_file(f)

