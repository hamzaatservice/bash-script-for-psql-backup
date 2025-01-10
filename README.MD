PostgreSQL Backup Script
Overview
This script automates the process of backing up a PostgreSQL database using information stored in a .pgpass file. It handles:

Extracting database connection details from the .pgpass file.
Performing a backup using pg_dump.
Cleaning up old backups to keep only the latest 5.
Prerequisites
PostgreSQL installed on your system.

The pg_dump utility available in your PATH.
A .pgpass file located at $HOME/db-backups-script/.pgpass with the following format:

hostname:port:database:username:password

Usage
Make the script executable:

chmod +x backup_script.sh

Run the script with the hostname as an argument:

./backup_script.sh your_hostname

To use all the designated host in .pgpass file use script all-loop-script.sh

./all-loop-script.sh

Notes


Ensure that the .pgpass file has the correct permissions set (e.g., chmod 600 ~/.pgpass).

The script will create a directory named database-hostname to store the backup files.

Backup files will be named in the format: database-hostname-timestamp.sql.

Old backups will be cleaned up, retaining only the 5 most recent backups.

Security Considerations

Store your .pgpass file securely, and ensure it has restricted access to prevent unauthorized access to your database credentials.

Consider using a vault solution for sensitive credentials management.

This script is flexible and can be modified to fit more specific backup strategies or needs.





