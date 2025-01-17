#!/bin/bash

# Path to the .pgpass file
PGPASS_FILE="/home/infrateam/auto-db-backups/.pgpass"

# Function to extract values from the .pgpass file
get_pgpass_details() {
    local pgpass_entry="$1"
    
    # Extract the details from the .pgpass entry
    IFS=':' read -r PG_HOST PG_PORT PG_DB PG_USER PG_PASS <<< "$pgpass_entry"

    # Export the details as environment variables
    export PGHOST="$PG_HOST"
    export PGPORT="$PG_PORT"
    export PGDATABASE="$PG_DB"
    export PGUSER="$PG_USER"
    export PGPASSWORD="$PG_PASS"
}

# Function to take a backup of the database
take_backup() {
    local pgpass_entry="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="${PGDATABASE}-${PGHOST}"
    local backup_file="${backup_dir}/${PGDATABASE}-${PGHOST}-${timestamp}.sql"

    # Create the directory if it doesn't exist
    mkdir -p "$backup_dir"

    echo "Taking backup for database $PGDATABASE on $PGHOST..."
    
    # Run pg_dump command to take the backup
    pg_dump -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" "$PGDATABASE" > "$backup_file"

    if [[ $? -eq 0 ]]; then
        echo "Backup successful! Backup file: $backup_file"
    else
        echo "Backup failed for database $PGDATABASE on $PGHOST"
    fi

    # Clean up old backups (keep only the latest 5)
    cleanup_old_backups "$backup_dir"
}

# Function to cleanup old backups
cleanup_old_backups() {
    local backup_dir="$1"

    # List files in the backup directory, sorted by modification time (latest first)
    files=($(ls -t "$backup_dir"/*.sql))

    # Check if there are more than 5 backups
    if [[ ${#files[@]} -gt 5 ]]; then
        # Delete the older backups (all except the last 5)
        for file in "${files[@]:5}"; do
            echo "Deleting old backup: $file"
            rm "$file"
        done
    fi
}

# Function to process each entry in the .pgpass file
process_pgpass_entries() {
    # Loop over each line in the .pgpass file
    while IFS= read -r pgpass_entry; do
        # Skip empty lines or comments
        if [[ -z "$pgpass_entry" || "$pgpass_entry" =~ ^# ]]; then
            continue
        fi

        # Get PostgreSQL connection details from the .pgpass entry
        get_pgpass_details "$pgpass_entry"

        # Take a backup for this database/host combination
        take_backup "$pgpass_entry"
    done < "$PGPASS_FILE"
}

# Main function to run the backup for all entries in .pgpass
main() {
    # Process each entry in the .pgpass file
    process_pgpass_entries
}

# Run the script
main
