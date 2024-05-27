#!/bin/bash

# Mount point directory
MOUNT_POINT="/path/to/mount/point"

# Threshold for disk usage (in percentage)
THRESHOLD=80

# Deletion objective threshold (in percentage)
DELETION_OBJECTIVE_THRESHOLD=65

# Log file for recording actions
LOG_FILE="/path/to/mount/point/rotate_log.log"

# Dry run mode (set to true for dry run)
DRY_RUN=true

# Size unit (set to "GB" or "MB")
SIZE_UNIT="MB"

# Function to calculate disk usage percentage
calculate_disk_usage_percentage() {
    local total_space=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $2}' | sed 's/[A-Z]//')
    local used_space=$(du -sh "$MOUNT_POINT" | awk '{print $1}' | sed 's/[A-Z]//')
    echo $(awk -v used="$used_space" -v total="$total_space" 'BEGIN { printf "%.0f", (used / total) * 100 }')
}

# Function to calculate file size
calculate_file_size() {
    if [ "$SIZE_UNIT" == "GB" ]; then
        local file_size=$(du -sh "$1" | awk '{print $1}' | sed 's/G//')
    else
        local file_size=$(du -shm "$1" | awk '{print $1}' | sed 's/M//')
    fi
    echo "$file_size"
}

# Function to calculate total space used
calculate_total_used_space() {
    local used_space=$(du -sh "$MOUNT_POINT" | awk '{print $1}' | sed 's/[A-Z]//')
    echo "$used_space"
}

# Rotate log file
echo "--------------------" >> $LOG_FILE
echo "Rotation started at $(date)" >> $LOG_FILE

# Check if current disk usage exceeds the threshold
if [ $(calculate_disk_usage_percentage) -ge $THRESHOLD ]; then
    total_used_space=$(calculate_total_used_space)
    total_freed_space=0
    files_to_delete=()
    n=1

    while true; do
        selected_files=$(find "$MOUNT_POINT" -type f -name "*.bak" -printf '%T+ %p\n' | sort | head -n $n | awk '{print $2}')
        total_freed_space=0
        files_to_delete=()

        for file in $selected_files; do
            file_size=$(calculate_file_size "$file")
            total_freed_space=$(awk -v total="$total_freed_space" -v size="$file_size" 'BEGIN { printf "%.2f", total + size }')
            files_to_delete+=("$file")
        done

        new_used_space=$(awk -v used="$total_used_space" -v freed="$total_freed_space" 'BEGIN { printf "%.2f", used - freed }')
        new_usage_percentage=$(awk -v used="$new_used_space" -v total=$(df -h "$MOUNT_POINT" | awk 'NR==2 {print $2}' | sed 's/[A-Z]//') 'BEGIN { printf "%.0f", (used / total) * 100 }')

        if [ "$new_usage_percentage" -le $DELETION_OBJECTIVE_THRESHOLD ]; then
            break
        else
            n=$((n + 1))
        fi
    done

    if [ "$DRY_RUN" == "true" ]; then
        echo "Dry run: Files to be deleted:" >> $LOG_FILE
        for file in "${files_to_delete[@]}"; do
            file_size=$(calculate_file_size "$file")
            echo "Dry run: $file ($file_size $SIZE_UNIT)" >> $LOG_FILE
        done
        echo "Dry run: Total space that would be freed: $total_freed_space $SIZE_UNIT" >> $LOG_FILE
        if [ "$new_usage_percentage" -le $DELETION_OBJECTIVE_THRESHOLD ]; then
            echo "Dry run: Deletion objective threshold would have been achieved." >> $LOG_FILE
        else
            echo "Dry run: Deletion objective threshold would not have been achieved." >> $LOG_FILE
        fi
    else
        for file in "${files_to_delete[@]}"; do
            rm -f "$file"
        done
        echo "Files deleted: ${files_to_delete[@]}" >> $LOG_FILE
        echo "Total space freed: $total_freed_space $SIZE_UNIT" >> $LOG_FILE
    fi
else
    echo "No rotation needed. Disk usage is below the threshold." >> $LOG_FILE
fi

echo "Rotation completed at $(date)" >> $LOG_FILE
echo "--------------------" >> $LOG_FILE
