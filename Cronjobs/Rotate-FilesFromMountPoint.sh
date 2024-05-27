#!/bin/bash

# Mount point directory
MOUNT_POINT="/path/to/mount/point"

# Threshold for disk usage (in percentage)
THRESHOLD=80

# Deletion objective threshold (in percentage)
DELETION_OBJECTIVE_THRESHOLD=65

# Log file for recording actions
LOG_FILE="/path/to/mount/point/rotate_log.log"

# Function to check disk usage
check_disk_usage() {
    df -h "$MOUNT_POINT" | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Function to delete oldest files
delete_oldest_files() {
    # Find and delete the oldest .bak files one by one
    find "$MOUNT_POINT" -type f -name "*.bak" -printf '%T+ %p\n' | sort | head -n 1 | awk '{print $2}' | xargs rm -f
}

# Rotate log file
echo "--------------------" >> $LOG_FILE
echo "Rotation started at $(date)" >> $LOG_FILE

# Check if current disk usage exceeds the threshold
if [ $(check_disk_usage) -ge $THRESHOLD ]; then
    while [ $(check_disk_usage) -ge $DELETION_OBJECTIVE_THRESHOLD ]; do
        OLDEST_FILE=$(find "$MOUNT_POINT" -type f -name "*.bak" -printf '%T+ %p\n' | sort | head -n 1 | awk '{print $2}')
        echo "Deleting $OLDEST_FILE" >> $LOG_FILE
        rm -f "$OLDEST_FILE"
        sleep 1
    done
fi

echo "Rotation completed at $(date)" >> $LOG_FILE
echo "--------------------" >> $LOG_FILE
