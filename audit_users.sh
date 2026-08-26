#!/bin/bash
# ======================
# Script  : audit_users.sh
# Purpose : To scan a csv file and determine or fix user profile errors.
# Author  : Artemis Churcher
# Date	  : 2026-08-21
# ======================

# if logs dir doesn't exist then create directory
if ! [ -d "user_audit_logs" ]; then
	mkdir user_audit_logs
fi
logFile="user_audit_logs/user_audit_log$(date '+%F.%H:%M:%S')"

# log function that takes a prefix and message to save to file
log(){
	prefix="$1"
	message="$2"
	echo "$prefix : $message" >> "$logFile"
}

# display help function after error or using -h or --help
help(){
	echo "This is a script that scans a csv file and modifies the current system to add or adjust users and groups."
	echo
	echo "-h or --help to display this message."
	echo
	echo "Input a csv file in variable 1 to scan."
	if [[ "$1" == "0" ]]; then
		exit 0
	else 
		exit 1
	fi
}

# display audit results after file runs
auditSummary(){
	echo "AUDIT SUMMARY"
	echo
	echo $(printf "%10s" 'Records read' ": $1")
	echo $(printf "%10s" "Already compliant" ": $2")
	echo $(printf "%10s" "Fixed" ": $3")
	echo $(printf "%10s" "Failed" ": $4")
	echo
	echo "~~ saved to $logFile ~~"
}

# Help options:
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	help 0
fi

# return log fields
c="COMPLIANT" 
f="FIXED"
e="ERROR"

# check to see if csv file location has been provided
if [[ -z "$1" ]]; then
	echo "No CSV file recorded. Please enter the file location:"
	read fileLocation;
	csv_file="$fileLocation"
elif ! [[ "$1" =~ \.csv ]]; then
	echo "ERROR: Not a CSV file. A CSV file is required for parsing."
	help 
else
	csv_file="$1"
fi

# check to see if file exists
if ! [[ -f "$csv_file" ]]; then
	echo "ERROR: File does not exist. Please provide a valid file location."
	help 
fi

# counter variables
i=0
error=0
fixed=0
compliant=0
{
	# read and discard header from file
	read -r header
	
	# split document into lines
	while IFS= read -r line || [[ -n "$line" ]]; do
		failed=false
		# increment index count
		((i++))
		
		# check to see if the line is blank or a comment
		if [[ -z "$line" || "$line" == \#* ]]; then
			log "$e" "The line is either blank or a comment."
			((error++))
			failed=true
			continue
		fi

		# convert line to 3 variables
		IFS="," read -r username groups shell <<< "$line"

		# check if fields have data
		if [[ -z "$username" || -z "$groups" || -z "$shell" ]]; then
			log "$e" "Entry has a missing field."
			((error++))
			failed=true
			continue
		fi

		# ^ anchors the start, $ the end, {0,31} limits the length
		if ! [[ "$username" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
			log "$e" "$username is not compliant with username standards."
			((error++))
			continue
		fi

		# check if user exists and creates user and shell directory if not
		if [[ -z $(getent passwd "$username" | cut -d: -f7) ]]; then
			log "$e" "username does not exist in system."
			((error++))
			failed=true
			useradd -m -s "$shell" "$username"
			# check addition did not fail
			if ! [[ -z $(getent passwd "$username" | cut -d: -f7)  ]]; then
				log "$f" "$username user has been added."
				((fixed++))
				continue
			else
				log "$e" "Failed to add $username."
				((error++))
				continue
			fi
		fi

		IFS="/" read -a group_array  <<< "$groups";
		for group in "${group_array[@]}"; do
			# check if group exists, log, then create group if not
			if [[ -z $(getent group "$group") ]]; then
				log "$e" "$group group does not exist."
				failed=true
				groupadd "$group"
				# check {group_array[$group]} did not fail
				if [[ -n $(getent group "$group") ]]; then
					log "$f" "$group group has been added."
					((fixed++))
					# add user to newly created group
					usermod -aG "$group" "$username"
					log "$f" "$username added to $group."
					((fixed++))
					
				else
					log "$e" "Failed to add $group group."
					((error++))
					
				fi
			fi

			if [[ "$failed" == true ]]; then
				continue
			fi

			# check if user is part of group
			if !  [[ $(id -nG "$username")  == *"$group"* ]]; then
				log "$e" "$username is not a member of $group."
				((error++))
				failed=true
				usermod -aG "$group" "$username"
				# check addition did not fail
				if  [[ $(id -nG "$username") == *"$group"* ]]; then
					log "$f" "$username added to $group."
					((fixed++))
					continue
				else
					log "$e" "Failed to add $username to $group."
					((error++))
					continue
				fi
			fi		
		done

		
		
		# -nG prints the group names the user belongs to, space separated
		#id -nG "$username"
		# %U is the owning user, %a the octal permission bits
		#stat -c '%U %a' "/home/$username"

		if [[ "$failed" == false ]]; then
			# finalise checks on user and log compliance
			log "$c" "$username is compliant"
			((compliant++))
		fi
	done 
} < "$csv_file"

auditSummary "$i" "$compliant" "$fixed" "$error"
