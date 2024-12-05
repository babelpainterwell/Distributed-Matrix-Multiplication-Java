#!/usr/bin/env python3
import sys
import json
import numpy as np
from collections import defaultdict

def reducer():
    current_key = None 
    A_blocks = defaultdict(list)
    B_blocks = defaultdict(list)

    for line in sys.stdin:
        key, value = line.strip().split("\t")
        value = json.loads(value)

        if key != current_key:
            if current_key is not None:
                compute_and_emit(current_key, A_blocks, B_blocks)
            current_key = key
            # clear the dictionaries
            A_blocks = defaultdict(list)
            B_blocks = defaultdict(list)


def compute_and_emit(key, A_blocks, B_blocks):
    i, j = map(int, key.split(','))
    result_block = None 

    for k in A_blocks.keys():
        if k in B_blocks:
            # only multiply if the blocks with the same k are found in both matrices
            