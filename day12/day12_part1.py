#!/usr/bin/env python

import sys
from itertools import groupby

def generate_combinations(x):
  ys = [x]
  while '?' in ys[0]:
    x=ys.pop(0)
    ys.append(x.replace('?', '#', 1))
    ys.append(x.replace('?', '.', 1))
  return ys

def count_spans(y):
  return ','.join([str(len(list(g))) for _, g in groupby(y) if _ == '#'])

# print the number of matches for each generated combination for every line
# sum the lines to get the final result
# ./day12_part1.py < input.txt | awk '{s+=$1} END {print s}'
if __name__ == '__main__':
  try:
    for line in sys.stdin:
      x, z = line.strip().split(' ', 1)
      print(sum([1 for y in generate_combinations(x) if count_spans(y) == z]))

  except KeyboardInterrupt:
    sys.exit(0)
