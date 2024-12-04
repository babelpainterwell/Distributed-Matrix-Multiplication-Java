## Dense Matrix Multiplication with Block Partitioning (B-B)

Goal: Compute the product C = A×B for two dense matrices A and B by partitioning both matrices into blocks.

Bonus Goal: Memory-awareness through controlling of region size. The best value for r is found through binary search: If the matrix cover for some value of r creates tasks that exceed memory size, then a larger r is explored; and vice versa. However, increasing the number of regions will decrease per-task input and output size, but it increases total cost because more duplicates of input tuples are created for the additional regions.

1. Determine Block Sizes
2. Divide Matrices into Blocks
3. Assign Block Indices
