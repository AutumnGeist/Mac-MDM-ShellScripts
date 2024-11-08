#!/bin/bash

# script to demote an Admin account to a Standard User account.

# Get a list of admin users excluding the "Admin" and "root" accounts
admins=$(dscl . -read /Groups/admin GroupMembership | awk '/GroupMembership/ {for (i=2;i<=NF;i++) if ($i != "admin" && $i != "root" && $(i+1) != "Admin") print $i}')

if [ -n "$admins" ]; then
    echo "Admin account(s) found: $admins"
    for admin_username in $admins; do
        echo "Demoting user '$admin_username'..."
        # Remove the user from the admin group
        sudo dscl . -delete "/Groups/admin" GroupMembership "$admin_username"
        # Add the user to the standard user group (may vary based on macOS version)
        sudo dseditgroup -o edit -d "$admin_username" -t user admin
        echo "User '$admin_username' demoted successfully."
    done
else
    echo "No admin account found other than 'Admin'."
fi
