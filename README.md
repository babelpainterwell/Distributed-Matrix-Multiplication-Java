# Dense Matrix Multiplication with Block Partitioning (B-B)

This project demonstrates how to compute the product **C = A × B** for two dense matrices **A** and **B** using a block partitioning approach. By dividing the matrices into smaller blocks, we can exploit parallelism and potentially improve performance on large-scale datasets and distributed computing platforms like Hadoop.

## Overview

1. **Determine Block Sizes**: Decide on the size of the blocks (e.g., 200x200, 500x500, etc.).
2. **Divide Matrices into Blocks**: Split the large matrices **A** and **B** into submatrices (blocks).
3. **Assign Block Indices**: Each block is indexed by a pair `(i, k)` for **A** and `(k, j)` for **B**, which will correspond to `(i, j)` blocks in the result **C**.

## Data Format

Each line of the input represents a single block. For example:

**For A**:

```bash
A i k 1,2;3,4
```

- `A` indicates this block is from matrix **A**.
- `i, k` are the block’s row and column indices in matrix **A**’s block grid.
- `1,2;3,4` represents the block’s actual numeric data (two rows: `[1,2]` and `[3,4]`).

**For B**:

```bash
B k j 5,6;7,8
```

- `B` indicates this block is from matrix **B**.
- `k, j` are the block’s row and column indices in matrix **B**’s block grid.
- `5,6;7,8` represents the block’s data.

## MapReduce Job Flow

### Driver (MatrixMultiplyDriver.java)

- **Responsibilities**:
  - Parse command-line arguments: `inputPath`, `outputPath`, `numBlockRowsC`, `numBlockColsC`.
  - Configure the job (mapper, reducer, output key/value classes, input/output format).
  - Run the job and exit based on success/failure.

### Mapper (MatrixMultiplyMapper.java)

- **Input**: One line of input containing a single block.
- **Parsing**:
  - Identify the matrix name: `A` or `B`.
  - Extract the block indices `(i, k)` for `A` or `(k, j)` for `B`.
  - Extract the block’s numeric data.
- **Emissions**:
  - If the block is from `A`, emit `(i, j)` as the key for **all** `j` in `[0..numBlockColsC-1]`.
    - Value format: `A,k,blockData`
  - If the block is from `B`, emit `(i, j)` as the key for **all** `i` in `[0..numBlockRowsC-1]`.
    - Value format: `B,k,blockData`

### Reducer (MatrixMultiplyReducer.java)

- **Input**: All values for a given key `(i, j)`.
- **Process**:
  - Group the received blocks into `A_blocks` and `B_blocks` by matching their `k` index.
  - For each `k`, multiply the `A` block and `B` block and accumulate into the resulting `C_ij` block.
- **Output**:
  - Emit `(i, j)` as the key and the computed `C_ij` block as the value.

## Data Generation and Partitioning

There are two main steps in generating the input data for our matrix multiplication **and the scripts for both are provided by CHATGPT**:

1. **Using Base Data Generation Scripts**:

   - `generate_base_data.sh`: Generates smaller “base” datasets for A and B.
   - `generate_full_data_from_base.sh`: Creates full-size `A_full.txt` and `B_full.txt` by **repetition**.

2. **Partition the Matrices into blocks**:

   ```bash
   ./partition_matrix.sh A 8000 6000 200 full_data/A_full.txt
   # Creates input_large/A_blocks.txt

   ./partition_matrix.sh B 6000 4000 200 full_data/B_full.txt
   # Creates input_large/B_blocks.txt
   ```

To generate the data:

```bash
# Generate base data
./generate_base_data.sh

# Create full-size data from base
./generate_full_data_from_base.sh
```

We can run the partitioning script with different parameters to produce different dataset configurations:

Example (Block size = 500):

```bash
./generate_base_data.sh
./generate_full_data_from_base.sh

BLOCK_SIZE=500 ./partition_matrix.sh A 8000 6000 500 full_data/A_full.txt
BLOCK_SIZE=500 ./partition_matrix.sh B 6000 4000 500 full_data/B_full.txt
```

By adjusting the BLOCK_SIZE, we can experiment with performance and memory usage trade-offs. Larger blocks may reduce overhead but increase memory pressure, while smaller blocks can help with distributing work more evenly across nodes.

## Running Locally

To run the computation locally:

```bash
make local
```

For different block sizes:

```bash
make local BLOCK_SIZE=500
```

## Running on AWS EMR

When running on AWS EMR, we can specify parameters such as CLUSTER_CORE_NODES to scale out your cluster:

```bash
make aws
make aws CLUSTER_CORE_NODES=6
```

Or specify both BLOCK_SIZE and number of core nodes:

```bash
make aws BLOCK_SIZE=500
make aws BLOCK_SIZE=500 CLUSTER_CORE_NODES=6
```

This will:

- Spin up a cluster with 6 core nodes on AWS EMR.
- Use a block size of 500 for partitioned input.
- Run the Hadoop job on the cluster.

Once the job completes, we can download the output results:

```bash
# Download output from AWS
make download-output-aws
make download-output-aws CLUSTER_CORE_NODES=6

# Download output with block size 500
make download-output-aws BLOCK_SIZE=500
make download-output-aws BLOCK_SIZE=500 CLUSTER_CORE_NODES=6
```
