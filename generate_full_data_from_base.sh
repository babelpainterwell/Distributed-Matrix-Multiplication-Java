#!/bin/bash
# generate_full_data_from_base.sh
#
# This script uses the small base datasets to create large full datasets by replication.
#
# Desired final sizes:
A_ROWS=8000
A_COLS=6000
B_ROWS=6000
B_COLS=4000

# Base file settings (must match what we generated in generate_base_data.sh)
A_BASE_ROWS=20
A_BASE_COLS=6000
B_BASE_ROWS=20
B_BASE_COLS=4000

A_BASE_FILE=base_data/A_base.txt
B_BASE_FILE=base_data/B_base.txt

# Validate base files
if [ ! -f "$A_BASE_FILE" ]; then
    echo "Error: $A_BASE_FILE does not exist. Run generate_base_data.sh first."
    exit 1
fi

if [ ! -f "$B_BASE_FILE" ]; then
    echo "Error: $B_BASE_FILE does not exist. Run generate_base_data.sh first."
    exit 1
fi

# Ensure the base dimensions match what we expect
if [ $A_BASE_COLS -ne $A_COLS ]; then
    echo "Error: A_BASE_COLS ($A_BASE_COLS) does not match A_COLS ($A_COLS)"
    exit 1
fi
if [ $B_BASE_COLS -ne $B_COLS ]; then
    echo "Error: B_BASE_COLS ($B_BASE_COLS) does not match B_COLS ($B_COLS)"
    exit 1
fi

FULL_DIR=full_data
mkdir -p $FULL_DIR
A_FULL_FILE=${FULL_DIR}/A_full.txt
B_FULL_FILE=${FULL_DIR}/B_full.txt

rm -f $A_FULL_FILE $B_FULL_FILE

# Compute how many times to replicate
A_factor=$((A_ROWS / A_BASE_ROWS))
B_factor=$((B_ROWS / B_BASE_ROWS))

if [ $((A_factor * A_BASE_ROWS)) -ne $A_ROWS ]; then
    echo "Warning: A_ROWS is not an exact multiple of A_BASE_ROWS. Some rows may be missing or duplicated."
fi
if [ $((B_factor * B_BASE_ROWS)) -ne $B_ROWS ]; then
    echo "Warning: B_ROWS is not an exact multiple of B_BASE_ROWS. Some rows may be missing or duplicated."
fi

echo "Creating A_full.txt (${A_ROWS}x${A_COLS}) by replicating A_base.txt ($A_BASE_ROWS x $A_COLS) $A_factor times..."
for (( i=0; i<$A_factor; i++ )); do
    cat "$A_BASE_FILE" >> "$A_FULL_FILE"
done
echo "A_full.txt created at $A_FULL_FILE."

echo "Creating B_full.txt (${B_ROWS}x${B_COLS}) by replicating B_base.txt ($B_BASE_ROWS x $B_COLS) $B_factor times..."
for (( i=0; i<$B_factor; i++ )); do
    cat "$B_BASE_FILE" >> "$B_FULL_FILE"
done
echo "B_full.txt created at $B_FULL_FILE."

echo "Full data generation completed in $FULL_DIR."
