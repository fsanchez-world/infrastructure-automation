#!/bin/bash

# Directory to create test files in
TEST_DIR="/path/to/test/dir"

# File size in MB
FILE_SIZE_MB=10

# Total number of months and files per month
TOTAL_MONTHS=7
FILES_PER_MONTH=20

# Log file to store creation details
LOG_FILE="$(pwd)/file_creation_log.txt"

# Find the device for the specified test directory
DEVICE=$(df "$TEST_DIR" | awk 'NR==2 {print $1}')

# Print the configuration for user reference
echo "Test Directory: $TEST_DIR" | tee -a "$LOG_FILE"
echo "File Size (MB): $FILE_SIZE_MB" | tee -a "$LOG_FILE"
echo "Total Months: $TOTAL_MONTHS" | tee -a "$LOG_FILE"
echo "Files Per Month: $FILES_PER_MONTH" | tee -a "$LOG_FILE"
echo "Device: $DEVICE" | tee -a "$LOG_FILE"

# Create test directory if it doesn't exist
mkdir -p "$TEST_DIR"

# Create files with different creation dates
for month in $(seq 0 $((TOTAL_MONTHS - 1))); do
  for day in $(seq 1 $FILES_PER_MONTH); do
    # Calculate the date for each file
    FILE_DATE=$(date -d "-$((month * 30 + day)) days" "+%Y%m%d%H%M")

    # Create the file
    FILE_NAME="$TEST_DIR/file_$((month * FILES_PER_MONTH + day))"
    dd if=/dev/zero of="$FILE_NAME" bs=1M count=$FILE_SIZE_MB

    # Echo and log the file creation details
    FILE_CREATION_DATE=$(date -d "-$((month * 30 + day)) days")
    echo "Creating file: $FILE_NAME with date: $FILE_CREATION_DATE" | tee -a "$LOG_FILE"

    # Set the creation date using debugfs
    touch -d "-$((month * 30 + day)) days" "$FILE_NAME"
    debugfs -w -R "set_inode_field $FILE_NAME crtime $FILE_DATE" "$DEVICE"
  done
done

echo "Test files created with varying creation dates spanning the last 7 months." | tee -a "$LOG_FILE"
