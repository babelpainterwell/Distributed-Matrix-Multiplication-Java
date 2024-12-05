#!/usr/bin/env python3
import sys
import json

def mapper(num_block_rows_c, num_block_cols_c):
    for line in sys.stdin:
        record = json.loads(line)
        matrix_name = record['matrix']
        block_row = record['block_row']
        block_col = record['block_col']
        block_data = record['data']

        # Values are JSON strings containing the matrix name, shared dimension index k, and block data.

        if matrix_name == "A":
            i = block_row
            k = block_col # shared dimension
            for j in range(num_block_cols_c):
                key = f"{i},{j}"
                value = {
                    "matrix": "A",
                    "k": k,
                    "data": block_data
                }
                print(f"{key}\t{json.dumps(value)}")
        elif matrix_name == "B":
            k = block_row
            j = block_col
            for i in range(num_block_rows_c):
                key = f"{i},{j}"
                value = {
                    "matrix": "B",
                    "k": k,
                    "data": block_data
                }
                print(f"{key}\t{json.dumps(value)}")

if __name__ == '__main__':
    # input comes from standard input
    num_block_rows_c = int(sys.argv[1])
    num_block_cols_c = int(sys.argv[2])
    mapper(num_block_rows_c, num_block_cols_c)