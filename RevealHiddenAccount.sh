#!/bin/bash

# script to reveal hidden Admin account, used for IT troubleshooting.

dscl . create /Users/admin IsHidden 0

echo "Admin account has been revealed"