#!/bin/bash

# Script to rename corporate owned macOS device's computer name to "C-serialNumber"
# Log collection path: /Library/Logs/Microsoft/Intune/DeviceRename/DeviceRename.log

# Define variables
appname="DeviceRename"
logandmetadir="/Library/Logs/Microsoft/Intune/$appname"
log="$logandmetadir/$appname.log"

# Function to display error message and exit
exit_with_error() {
    echo "Error: $1"
    exit 1
}

# Check if the log directory has been created
if [ -d $logandmetadir ]; then
    # Already created
    echo "# $(date) | Log directory already exists - $logandmetadir"
else
    # Creating Metadirectory
    echo "# $(date) | creating log directory - $logandmetadir"
    mkdir -p $logandmetadir
fi

# Start logging
exec &> >(tee -a "$log")

# Begin Script Body
echo ""
echo "##############################################################"
echo "# $(date) | Starting $appname"
echo "##############################################################"
echo "Writing log output to [$log]"
echo ""

echo "$(date) | Checking if renaming is necessary..."

#  Check if computer is enrolled by ABM or BYOD
profiles status -type enrollment | grep -q "Enrolled via DEP: Yes"
if [ "$?" = "0" ]; then
  echo "$(date) | This device is enrolled by ABM"
else
  echo "$(date) | This device is not enrolled by ABM, device name will not be changed."
  echo "$(date) | exiting..."
  exit 0
fi

# Get current ComputerName
CurrentName=$(scutil --get ComputerName)
if [ "$?" = "0" ]; then
  echo "$(date) | Current computer name detected as $CurrentName"
else
   echo "$(date) | Unable to determine current name"
   exit_with_error "Unable to determine current name"
fi

# Get the serial number of the Mac
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
if [ -z "$serial" ]; then
    echo "$(date) | Unable to determine serial number"
    exit_with_error "Failed to retrieve serial number"
else
    echo "$(date) | Retrieved serial number: $serial"
fi

# Create new name by adding "C-" to the beginning of the serial number
NewName="C-$serial"

#  if the computer name is already set
if [[ "$CurrentName" == "$NewName" ]]; then
  echo "$(date) | Rename not required, already set to $CurrentName"
  exit 0
else
    echo "$(date) | Setting the new name..."
fi

# Set all computer names to new name
scutil --set HostName $NewName
if [ $? -ne 0 ]; then
    exit_with_error "Failed to set HostName"
else
    echo "$(date) | HostName changed from $CurrentName to $NewName"
fi

scutil --set LocalHostName $NewName
if [ $? -ne 0 ]; then
    exit_with_error "Failed to set LocalHostName"
else
    echo "$(date) | LocalHostName changed from $CurrentName to $NewName"
fi

scutil --set ComputerName $NewName
if [ $? -ne 0 ]; then
    exit_with_error "Failed to set ComputerName"
else
    echo "$(date) | Computername changed from $CurrentName to $NewName"
fi

echo "$(date) | Computer name has been successfully changed."