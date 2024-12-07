#!/bin/bash
# generate_base_data.sh
#
# This script generates small "base" datasets for A and B with random float values.
# We will later replicate these base datasets multiple times to achieve the full size.
#
# Adjust these parameters as needed.

A_BASE_ROWS=20
A_BASE_COLS=6000
B_BASE_ROWS=20
B_BASE_COLS=4000

mkdir -p base_data
A_BASE_FILE=base_data/A_base.txt
B_BASE_FILE=base_data/B_base.txt

rm -f $A_BASE_FILE $B_BASE_FILE

echo "Generating A_base.txt (${A_BASE_ROWS}x${A_BASE_COLS})..."
for (( i=0; i<$A_BASE_ROWS; i++ )); do
    row_data=""
    for (( j=0; j<$A_BASE_COLS; j++ )); do
        val=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf("%.4f", rand())}')
        if [ -z "$row_data" ]; then
            row_data="$val"
        else
            row_data="$row_data,$val"
        fi
    done
    echo "$row_data" >> "$A_BASE_FILE"
done
echo "A_base.txt generation completed at $A_BASE_FILE."

echo "Generating B_base.txt (${B_BASE_ROWS}x${B_BASE_COLS})..."
for (( i=0; i<$B_BASE_ROWS; i++ )); do
    row_data=""
    for (( j=0; j<$B_BASE_COLS; j++ )); do
        val=$(awk -v seed=$RANDOM 'BEGIN{srand(seed); printf("%.4f", rand())}')
        if [ -z "$row_data" ]; then
            row_data="$val"
        else
            row_data="$row_data,$val"
        fi
    done
    echo "$row_data" >> "$B_BASE_FILE"
done
echo "B_base.txt generation completed at $B_BASE_FILE."

echo "Base data generation finished."
