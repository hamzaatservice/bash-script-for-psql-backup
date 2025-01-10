#!/bin/bash

# Path to the .pgpass file
PGPASS_FILE="$HOME/db-backups-script/.pgpass"

# Function to extract values from the .pgpass file
get_pgpass_details() {
    local hostname="$1"

    # Extract the corresponding line from the .pgpass file
    details=$(grep "^$hostname:" "$PGPASS_FILE")

    if [[ -z "$details" ]]; then
        echo "No matching entry found for $hostname in .pgpass."
        exit 1
    fi

    # Extract the details from the line
    IFS=':' read -r PG_HOST PG_PORT PG_DB PG_USER PG_PASS <<< "$details"

    # Export the details as environment variables
    export PGHOST="$PG_HOST"
    export PGPORT="$PG_PORT"
    export PGDATABASE="$PG_DB"
    export PGUSER="$PG_USER"
    export PGPASSWORD="$PG_PASS"
}

# Function to take a backup of the database
take_backup() {
    local hostname="$1"
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

# Main function to run the backup for a given host
main() {
    if [[ -z "$1" ]]; then
        echo "Please provide the hostname for the backup."
        exit 1
    fi

    local hostname="$1"

    # Get PostgreSQL connection details from .pgpass
    get_pgpass_details "$hostname"

    # Take a backup of the database
    take_backup "$hostname"
}

# Run the script with the first argument as the hostname
main "$1"
