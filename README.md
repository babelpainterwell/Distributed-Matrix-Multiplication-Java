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

The input files need to be formatted in a way that the mapper can understand.
In our case, each line in the input files is a JSON-formatted string representing a block of the matrix.
The generate_matrices.py script creates these files and writes the data in the required format.
