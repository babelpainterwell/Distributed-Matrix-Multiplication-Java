## Dense Matrix Multiplication with Block Partitioning (B-B)

Goal: Compute the product C = A×B for two dense matrices A and B by partitioning both matrices into blocks.

Bonus Goal: Memory-awareness through controlling of region size. The best value for r is found through binary search: If the matrix cover for some value of r creates tasks that exceed memory size, then a larger r is explored; and vice versa. However, increasing the number of regions will decrease per-task input and output size, but it increases total cost because more duplicates of input tuples are created for the additional regions.

1. Determine Block Sizes
2. Divide Matrices into Blocks
3. Assign Block Indices

Issues with Random Assignment:assigning blocks to random rows or columns would mix up blocks that are not supposed to be multiplied together.

#### Create a virtual environment named 'venv'

python3 -m venv venv

source venv/bin/activate

pip install -r requirements.txt

#### Hadoop Streaming Mechanism:

Hadoop handles the distribution of input files to the mapper tasks.
Each mapper receives input data via stdin (standard input), which reads data from the files specified in the -input argument of the Hadoop command. The data is presented to the mapper as a stream of lines, which the mapper processes one by one.

#### Input Data Format:

Data Format for Input Blocks: Assume each line in the input files describes one block. For example:

css
Copy code
A i k 1,2;3,4
A indicates a block from matrix A.
i, k are the block’s row and column indices for matrix A.
1,2;3,4 represents the block’s rows and columns (two rows: [1,2] and [3,4]).

Similarly, for B:

css
Copy code
B k j 5,6;7,8
B indicates a block from matrix B.
k, j are the block’s row and column indices for matrix B.

Driver Class (MatrixMultiplyDriver.java): The driver class will:

- Parse command-line arguments: inputPath, outputPath, numBlockRowsC, numBlockColsC.
- Set these values in the Configuration.
  Configure the job (mapper, reducer, output key/value classes, input/output format).
- Run the job and exit based on success/failure.

Mapper (MatrixMultiplyMapper.java): The mapper reads one line at a time. For each line:

- Parse the matrix name (A or B), the indices (i,k or k,j), and the block data.
- If the block is from A, for each j in [0..numBlockColsC-1], emit (i,j) as key and a value like A,k,blockData.
- If the block is from B, for each i in [0..numBlockRowsC-1], emit (i,j) as key and B,k,blockData.

Reducer (MatrixMultiplyReducer.java): The reducer receives all values for a key (i,j).

- Partition values into A_blocks and B_blocks based on k.
- Multiply corresponding A_blocks and B_blocks to produce C_ij.
  Emit (i,j) and the resulting C_ij block.
