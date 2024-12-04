import os 
import numpy as np
import argparse
import json

def generate_matrix(rows, cols):
    return np.random.rand(rows, cols)

def partition_matrix(matrix, block_size, matrix_name, output_dir):
    num_block_rows = int(np.ceil(matrix.shape[0] / block_size))
    num_block_cols = int(np.ceil(matrix.shape[1] / block_size))

    for i in range(num_block_rows):
        for j in range(num_block_cols):
            row_start = i * block_size 
            row_end = min((i + 1) * block_size, matrix.shape[0]) # in case the last block is smaller
            col_start = j * block_size
            col_end = min((j + 1) * block_size, matrix.shape[1])

            block = matrix[row_start:row_end, col_start:col_end]
            block_data = {
                "matrix": matrix_name,
                "block_row": i,
                "block_col": j,
                "data": block.tolist()
            }

            output_path = os.path.join(output_dir, f'part_{i}_{j}')
            with open(output_path, 'w') as f:
                json.dump(block_data, f)

def main():
    parser = argparse.ArgumentParser(description='Generate and partition matrices.')
    parser.add_argument('--m', type=int, required=True, help='Number of rows in matrix A')
    parser.add_argument('--n', type=int, required=True, help='Number of columns in matrix A and rows in matrix B')
    parser.add_argument('--p', type=int, required=True, help='Number of columns in matrix B')
    parser.add_argument('--block_size', type=int, required=True, help='Block size for partitioning')
    parser.add_argument('--output_dir', type=str, default='data/input', help='Output directory')
    args = parser.parse_args()

    A_output_dir = os.path.join(args.output_dir, 'A')
    B_output_dir = os.path.join(args.output_dir, 'B')
    os.makedirs(A_output_dir, exist_ok=True)
    os.makedirs(B_output_dir, exist_ok=True)

    print('Generating matrices...')
    A = generate_matrix(args.m, args.n)
    print(A)
    B = generate_matrix(args.n, args.p)
    print(B)

    print('Partitioning matrices...')
    partition_matrix(A, args.block_size, 'A', A_output_dir)
    partition_matrix(B, args.block_size, 'B', B_output_dir)

    print("Matrices generated and partitioned successfully.")


if __name__ == '__main__':
    main()