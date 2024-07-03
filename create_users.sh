#!/bin/bash

# script that creates users and groups as specified

# Verify that an input file has been specified
# checks the number of arguments ($#) is not equal to 1 (-ne)
if [[ $# -ne 1 ]]; then
    echo "Error: No input file specified."
    echo "usage: $(basename "$0") <input_file>"
    exit 1
fi


# FILES
# Log file to log all actions
LOG_FILE="/var/log/user_management.log"
# store generated passwords in user_passwords.txt
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure both files exist
touch $LOG_FILE
touch $PASSWORD_FILE

# Set permissions for password file
chmod 600 $PASSWORD_FILE

# PASSWORD
# install pwgen to generate random password and check its version
sudo apt-get update
sudo apt-get install pwgen
pwgen --version

# function to generate random password 
generate_password() {
    local pasword_length=${1:-12}
    pwgen -s $password_length 1
}


echo "user created successfully." | tee -a $LOG_FILE
