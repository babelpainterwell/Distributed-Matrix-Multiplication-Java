#!/usr/bin/env python3
import sys
import json
import numpy as np
from collections import defaultdict

def reducer():
    current_key = None 
    # only one block for each k in A and B
    A_blocks = {}
    B_blocks = {}

    for line in sys.stdin:
        key, value = line.strip().split("\t")
        value = json.loads(value)

        if key != current_key:
            if current_key is not None:
                compute_and_emit(current_key, A_blocks, B_blocks)
            current_key = key
            A_blocks = {}
            B_blocks = {}
        
        matrix_name = value['matrix']
        k = value['k']
        data = value['data']

        if matrix_name == 'A':
            A_blocks[k] = data
        elif matrix_name == 'B':
            B_blocks[k] = data



def compute_and_emit(key, A_blocks, B_blocks):
    i, j = map(int, key.split(','))
    result_block = None 

    for k in A_blocks.keys():
        if k in B_blocks:
            # only multiply if the blocks with the same k are found in both matrices
            A_block = np.array(A_blocks[k])
            B_block = np.array(B_blocks[k])
            product = np.dot(A_block, B_block)
            if result_block is None:
                result_block = product
            else:
                result_block += product
    
    if result_block is not None:
        output = {
            "block_row": i,
            "block_col": j,
            "data": result_block.tolist()
        }
        print(f"{key}\t{json.dumps(output)}")

if __name__ == '__main__':
    reducer()