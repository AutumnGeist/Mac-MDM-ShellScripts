#!/bin/bash

# script to reset the admin password on corporate-owned macOS devices.

# Assign arguments to variables
username="Admin"
oldpwd="currentPwd" # change to current password
newpwd="newPwd" # change to new password, must meet password complexity requirements

# Check if the user exists
if id $username 2>/dev/null; then
    # Change the user's password
    if dscl . -passwd /Users/"$username" "$oldpwd" "$newpwd"; then
        echo "Password for $username has been changed."

        # Update the keychain password
        if security set-keychain-password -o "$oldpwd" -p  "$newpwd" "/Users/$username/Library/Keychains/login.keychain"; then
            echo "Keychain password updated."
        else
            echo "Failed to update keychain password."
            exit 1
        fi
    else
        echo "Failed to change the password for $username."
        exit 1
    fi
else
    echo "User $username does not exist."
    exit 1
fi