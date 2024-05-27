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

# Debug mode (set to true for debug logging)
DEBUG=true

# Function to log debug messages
debug_log() {
    if [ "$DEBUG" == "true" ]; then
        echo "DEBUG: $1" >> $LOG_FILE
    fi
}

# Function to convert human-readable size to bytes
human_readable_to_bytes() {
    local size=$1
    case ${size: -1} in
        K|k) echo $((${size::-1} * 1024)) ;;
        M|m) echo $((${size::-1} * 1024 * 1024)) ;;
        G|g) echo $((${size::-1} * 1024 * 1024 * 1024)) ;;
        T|t) echo $((${size::-1} * 1024 * 1024 * 1024 * 1024)) ;;
        *) echo $size ;;
    esac
}

# Function to calculate disk usage percentage
calculate_disk_usage_percentage() {
    local total_space_bytes=$(df --block-size=1 "$MOUNT_POINT" | awk 'NR==2 {print $2}')
    local used_space_bytes=$(df --block-size=1 "$MOUNT_POINT" | awk 'NR==2 {print $3}')
    debug_log "Total space (bytes): $total_space_bytes"
    debug_log "Used space (bytes): $used_space_bytes"
    echo $(awk -v used="$used_space_bytes" -v total="$total_space_bytes" 'BEGIN { printf "%.0f", (used / total) * 100 }')
}

# Function to calculate file size in bytes
calculate_file_size_bytes() {
    local file_size=$(du -sb "$1" | awk '{print $1}')
    debug_log "File size of $1: $file_size bytes"
    echo "$file_size"
}

# Function to calculate total used space in bytes
calculate_total_used_space_bytes() {
    local used_space_bytes=$(du -sb "$MOUNT_POINT" | awk '{print $1}')
    debug_log "Total used space (bytes): $used_space_bytes"
    echo "$used_space_bytes"
}

# Rotate log file
echo "--------------------" >> $LOG_FILE
echo "Rotation started at $(date)" >> $LOG_FILE

# Check if current disk usage exceeds the threshold
current_usage_percentage=$(calculate_disk_usage_percentage)
debug_log "Current disk usage percentage: $current_usage_percentage"

if [ "$current_usage_percentage" -ge $THRESHOLD ]; then
    total_used_space_bytes=$(calculate_total_used_space_bytes)
    total_freed_space_bytes=0
    files_to_delete=()
    n=1

    while true; do
        selected_files=$(find "$MOUNT_POINT" -type f -name "*.bak" -printf '%T+ %p\n' | sort | head -n $n | awk '{print $2}')
        total_freed_space_bytes=0
        files_to_delete=()

        debug_log "Selected files (iteration $n): $selected_files"

        for file in $selected_files; do
            file_size_bytes=$(calculate_file_size_bytes "$file")
            total_freed_space_bytes=$(($total_freed_space_bytes + $file_size_bytes))
            files_to_delete+=("$file")
        done

        debug_log "Total freed space after iteration $n: $total_freed_space_bytes bytes"
        debug_log "Files to delete after iteration $n: ${files_to_delete[@]}"

        new_used_space_bytes=$(($total_used_space_bytes - $total_freed_space_bytes))
        debug_log "New used space (bytes) after freeing space: $new_used_space_bytes"

        total_space_bytes=$(df --block-size=1 "$MOUNT_POINT" | awk 'NR==2 {print $2}')
        new_usage_percentage=$(awk -v used="$new_used_space_bytes" -v total="$total_space_bytes" 'BEGIN { printf "%.0f", (used / total) * 100 }')
        debug_log "New disk usage percentage: $new_usage_percentage"

        if [ "$new_usage_percentage" -le $DELETION_OBJECTIVE_THRESHOLD ]; then
            break
        else
            n=$((n + 1))
        fi
    done

    if [ "$DRY_RUN" == "true" ]; then
        echo "Dry run: Files to be deleted:" >> $LOG_FILE
        for file in "${files_to_delete[@]}"; do
            file_size_bytes=$(calculate_file_size_bytes "$file")
            echo "Dry run: $file ($file_size_bytes bytes)" >> $LOG_FILE
        done
        echo "Dry run: Total space that would be freed: $total_freed_space_bytes bytes" >> $LOG_FILE
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
        echo "Total space freed: $total_freed_space_bytes bytes" >> $LOG_FILE
    fi
else
    echo "No rotation needed. Disk usage is below the threshold." >> $LOG_FILE
fi

echo "Rotation completed at $(date)" >> $LOG_FILE
echo "--------------------" >> $LOG_FILE
