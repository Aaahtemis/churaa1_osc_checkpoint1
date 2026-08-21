#!/bin/bash
# ======================
# Script  : audit_users.sh
# Purpose : To scan a csv file and determine or fix user profile errors.
# Author  : Artemis Churcher
# Date	  : 2026-08-21
# ======================

# read csv line by line * split records into 3 parts

# break csv into lines
# skip blank lines & lines starting with #


#loop lines
# var 1 = section 1
# var 2 = section 2
# var 3 = section 3

# if var1 == empty || var2 == empty || var3 == empty
# 	return error
#	next loop

# if var1[0] not lowercase || var1[1..] not lowercase/digits/hyphens/underscores
#	return error
#	next loop


# return log fields
c="COMPLIANT: " 
f="FIXED: "
e="ERROR: "

# print console number of each field and total records

if [[ -z "$1" ]]; then
echo "File Location:"
read fileLocation;
csv_file="$fileLocation"
else
csv_file="$1"
fi

logFile="userLogs/userChecksLog_%y-%m-%d-%H:%M:%S"

while IFS=',' read -r username groupname shell; do
	# the three fields are now separate variables
done < "$csv_file"

# ^ anchors the start, $ the end, {0,31} limits the length
if ! [[ "$username" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
	echo "%e%username is not compliant with standards." >> logFile;
	continue
	# log the error, then 'continue' to the next record
fi

# Field 7 of the passwd record is the login shell
#getent passwd "$username" | cut -d: -f7
# -nG prints the group names the user belongs to, space separated
#id -nG "$username"
# %U is the owning user, %a the octal permission bits
#stat -c '%U %a' "/home/$username"
