#!/bin/bash

# script to promote a Standard User account to Admin.

# Get a list of standard users (excluding "Admin")
standard_users=$(dscl . -list /Users UniqueID | awk '$2 >= 501 && $2 < 1000 {print $1}' | grep -v -e '^_' -e '^admin' -e '^admin' -e '^root' -e '^nobody')

if [ -n "$standard_users" ]; then
    echo "Standard user(s) found: $standard_users"
    for standard_username in $standard_users; do
        echo "Promoting user '$standard_username'..."
        # Add the user to the admin group
        dseditgroup -o edit -a "$standard_username" -t user admin
        echo "User '$standard_username' promoted to admin successfully."
    done
else
    echo "No standard user found to promote."
fi