#!/bin/bash
# partition_matrix.sh
#
# This script partitions a full matrix file into block format:
# M i j block_data
#
# Arguments:
# 1: MATRIX_NAME (A or B)
# 2: ROWS
# 3: COLS
# 4: BLOCK_SIZE
# 5: input_file (e.g., A_full.txt or B_full.txt)
#
# The script will create temporary files in input_large/temp_<MATRIX_NAME>
# and then produce input_large/A_blocks.txt or input_large/B_blocks.txt.

MATRIX_NAME=$1
ROWS=$2
COLS=$3
BLOCK_SIZE=$4
INPUT_FILE=$5

if [ -z "$MATRIX_NAME" ] || [ -z "$ROWS" ] || [ -z "$COLS" ] || [ -z "$BLOCK_SIZE" ] || [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <MATRIX_NAME> <ROWS> <COLS> <BLOCK_SIZE> <input_file>"
    exit 1
fi

OUTPUT_DIR="input_large"
mkdir -p "${OUTPUT_DIR}"

TEMP_DIR="${OUTPUT_DIR}/temp_${MATRIX_NAME}"
mkdir -p "${TEMP_DIR}"

numBlockRows=$((ROWS / BLOCK_SIZE))
numBlockCols=$((COLS / BLOCK_SIZE))

# Initialize empty temp files for each block
for ((i_block=0; i_block<numBlockRows; i_block++)); do
  for ((j_block=0; j_block<numBlockCols; j_block++)); do
    > "${TEMP_DIR}/${MATRIX_NAME}_${i_block}_${j_block}.tmp"
  done
done

echo "Partitioning ${MATRIX_NAME} from ${INPUT_FILE} with BLOCK_SIZE=${BLOCK_SIZE}..."
line_num=0
while IFS= read -r line; do
  i_block=$((line_num / BLOCK_SIZE))
  IFS=',' read -ra values <<< "$line"
  for ((j_block=0; j_block<numBlockCols; j_block++)); do
    start_col=$((j_block * BLOCK_SIZE))
    segment=("${values[@]:$start_col:$BLOCK_SIZE}")
    row_data=$(IFS=,; echo "${segment[*]}")
    echo "$row_data" >> "${TEMP_DIR}/${MATRIX_NAME}_${i_block}_${j_block}.tmp"
  done
  ((line_num++))
done < "$INPUT_FILE"

# Assemble final blocks file
BLOCKS_FILE="${OUTPUT_DIR}/${MATRIX_NAME}_blocks.txt"
> "$BLOCKS_FILE"

echo "Assembling blocks into ${BLOCKS_FILE}..."
for ((i_block=0; i_block<numBlockRows; i_block++)); do
  for ((j_block=0; j_block<numBlockCols; j_block++)); do
    rows_in_block=()
    while IFS= read -r block_line; do
      rows_in_block+=("$block_line")
    done < "${TEMP_DIR}/${MATRIX_NAME}_${i_block}_${j_block}.tmp"
    # Join rows with ';'
    block_data=$(IFS=';'; echo "${rows_in_block[*]}")
    echo "${MATRIX_NAME} ${i_block} ${j_block} ${block_data}" >> "$BLOCKS_FILE"
  done
done

echo "Partitioning completed. Output: ${BLOCKS_FILE}"

# Clean up temp files
rm -rf "${TEMP_DIR}"
