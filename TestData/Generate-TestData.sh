#!/bin/bash

# Directory to create test files in
TEST_DIR="/path/to/test/dir"

# File size in MB
FILE_SIZE_MB=10

# Create test directory if it doesn't exist
mkdir -p "$TEST_DIR"

# Total number of months and files per month
TOTAL_MONTHS=7
FILES_PER_MONTH=20

# Create files with different creation dates
for month in $(seq 0 $((TOTAL_MONTHS - 1))); do
  for day in $(seq 1 $FILES_PER_MONTH); do
    # Calculate the date for each file
    FILE_DATE=$(date -d "-$((month * 30 + day)) days" "+%Y%m%d%H%M")

    # Create the file
    FILE_NAME="$TEST_DIR/file_$((month * FILES_PER_MONTH + day))"
    dd if=/dev/zero of="$FILE_NAME" bs=1M count=$FILE_SIZE_MB

    # Set the creation date using debugfs
    touch -d "-$((month * 30 + day)) days" "$FILE_NAME"
    debugfs -w -R "set_inode_field $FILE_NAME crtime $FILE_DATE" /dev/sdX
  done
done

echo "Test files created with varying creation dates spanning the last 7 months."
