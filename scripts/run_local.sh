#!/bin/bash

# Variables
NUM_REDUCERS=4
BLOCK_SIZE=2  # Adjust as needed
MATRIX_A_DIR="data/input/A"
MATRIX_B_DIR="data/input/B"
OUTPUT_DIR="data/output"
HADOOP_STREAMING_JAR="/usr/local/hadoop-3.3.5/share/hadoop/tools/lib/hadoop-streaming-3.3.5.jar"  # Update with your Hadoop installation path

# BELOW IS GIVEN BY CHATGPT
# BELOW IS GIVEN BY CHATGPT
# BELOW IS GIVEN BY CHATGPT


# Clean up output directory in Hadoop FileSystem
hadoop fs -rm -r -f ${OUTPUT_DIR}

# Determine the number of block rows and columns in A
NUM_BLOCK_ROWS_A=$(ls -1 ${MATRIX_A_DIR} | grep 'part_' | cut -d'_' -f2 | sort -n | uniq | wc -l)
NUM_BLOCK_COLS_A=$(ls -1 ${MATRIX_A_DIR} | grep 'part_' | cut -d'_' -f3 | sort -n | uniq | wc -l)

# Determine the number of block rows and columns in B
NUM_BLOCK_ROWS_B=$(ls -1 ${MATRIX_B_DIR} | grep 'part_' | cut -d'_' -f2 | sort -n | uniq | wc -l)
NUM_BLOCK_COLS_B=$(ls -1 ${MATRIX_B_DIR} | grep 'part_' | cut -d'_' -f3 | sort -n | uniq | wc -l)

# Number of block rows in C is same as NUM_BLOCK_ROWS_A
NUM_BLOCK_ROWS_C=${NUM_BLOCK_ROWS_A}
# Number of block columns in C is same as NUM_BLOCK_COLS_B
NUM_BLOCK_COLS_C=${NUM_BLOCK_COLS_B}

# Echo the block counts for verification
echo "NUM_BLOCK_ROWS_A=${NUM_BLOCK_ROWS_A}"
echo "NUM_BLOCK_COLS_A=${NUM_BLOCK_COLS_A}"
echo "NUM_BLOCK_ROWS_B=${NUM_BLOCK_ROWS_B}"
echo "NUM_BLOCK_COLS_B=${NUM_BLOCK_COLS_B}"
echo "NUM_BLOCK_ROWS_C=${NUM_BLOCK_ROWS_C}"
echo "NUM_BLOCK_COLS_C=${NUM_BLOCK_COLS_C}"

# Run Hadoop Streaming
hadoop jar ${HADOOP_STREAMING_JAR} \
    -D mapreduce.job.reduces=${NUM_REDUCERS} \
    -D fs.defaultFS=file:/// \
    -input ${MATRIX_A_DIR},${MATRIX_B_DIR} \
    -output ${OUTPUT_DIR} \
    -mapper "src/mapper.py ${NUM_BLOCK_ROWS_C} ${NUM_BLOCK_COLS_C}" \
    -reducer "src/reducer.py" \
    -file src/mapper.py \
    -file src/reducer.py
