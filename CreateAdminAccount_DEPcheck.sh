#!/bin/bash

# Script to create a hidden Admin account on corporate-owned macOS devices.
# Log collection path: /Library/Logs/Microsoft/Intune/CreateAdminAccount/CreateAdminAccount.log

# Define variables
username="Admin"
password="p@ssword" # must match current admin password
appname="CreateAdminAccount"
logandmetadir="/Library/Logs/Microsoft/Intune/$appname"
log="$logandmetadir/$appname.log"

# function to delay until the user has finished setup assistant.
waitforSetupAssistant () {
  until [[ -f /var/db/.AppleSetupDone ]]; do
    delay=$(( $RANDOM % 50 + 10 ))
    echo "$(date) |  + Setup Assistant not done, waiting [$delay] seconds"
    sleep $delay
  done
  echo "$(date) | Setup Assistant is done, continuing with the script"
}

#  Check if the log directory has been created
if [ -d $logandmetadir ]; then
    ## Already created
    echo "#$(date) | Log directory already exists - $logandmetadir"
else
    ## Creating Metadirectory
    echo "#$(date) | creating log directory - $logandmetadir"
    mkdir -p $logandmetadir
fi

# start logging
exec &> >(tee -a "$log")

# Begin script log body
echo ""
echo "##############################################################"
echo "# $(date) | Starting $appname"
echo "##############################################################"
echo "Writing log output to [$log]"
echo ""
echo "$(date) | Checking if Admin account is necessary..."

#  Check if computer is enrolled by ABM or BYOD
profiles status -type enrollment | grep -q "Enrolled via DEP: Yes"
if [ "$?" = "0" ]; then
  echo "$(date) | This device is enrolled by ABM"
else
  sudo sysadminctl -deleteUser "$username" # Remove existing admin account if it exists
  echo "$(date) | This device is not enrolled by ABM, admin account will not be created."
  echo "$(date) | exiting..."
  exit 0
fi

# Check if the admin account already exists
if id "$username" &>/dev/null; then
  echo "$(date) | User $username already exists. Exiting..."
  exit 0
fi

# Delay until the user has finished setup assistant
waitforSetupAssistant

echo "$(date) | Creating Admin account..."

# Create the new administrator user
dscl . -create /Users/"$username"
dscl . -create /Users/"$username" UserShell /bin/bash
dscl . -create /Users/"$username" RealName "Admin"
dscl . -create /Users/"$username" UniqueID "2001" # Ensure the UID is unique
dscl . -create /Users/"$username" PrimaryGroupID "80" # 80 is the default admin group
dscl . -create /Users/"$username" NFSHomeDirectory /Users/"$username"

# Set the password for the new user with password error handling
if ! dscl . -passwd /Users/"$username" "$password" 2>&1 | grep -q "eDSAuthPasswordQualityCheckFailed"; then
  echo "$(date) | Password set successfully."
else
  echo "$(date) | Error: Password quality check failed. Please choose a stronger password."
  exit 1
fi

# Add the new user to the admin group
dscl . -append /Groups/admin GroupMembership "$username"
echo "$(date) | Added to the admin group."

# Hide the Admin account
dscl . create /Users/$username IsHidden 1
echo "$(date) | Added account to hidden users list."

echo "$(date) | Admin account created successfully."


