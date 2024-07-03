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
mkdir -p /var/secure
touch $PASSWORD_FILE

# Set permissions for password file
chmod 600 $PASSWORD_FILE

# PASSWORD
# install pwgen to generate random password and check its version
sudo apt-get update
sudo apt-get install -y pwgen
if ! pwgen --version &>/dev/null; then
    echo "Error: pwgen installation failed." | tee -a $LOG_FILE
    exit 1
fi

# function to generate random password 
generate_password() {
    local password_length=${1:-12}
    pwgen -s $password_length 1
}

create_user() {
    # Create user group with same name as user
    # check iff user exists
    # create user with group
    # set permissions
    # run generate_password function
    # store password securely
    # add user to group

    local user=$1
    shift
    local groups=$@

    # Check if user already exists
    if id "$user" &>/dev/null; then
        echo "User $user already exists." | tee -a $LOG_FILE
        return 0
    fi

   
    if ! sudo groupadd "$user" 2>>$LOG_FILE; then
        echo "Failed to create group $user." | tee -a $LOG_FILE
        return 1
    fi

    # Create user and set their primary group
    if ! sudo useradd -m -g "$user" "$user" 2>>$LOG_FILE; then
        echo "Failed to create user $user." | tee -a $LOG_FILE
        return 1
    fi

    # Create additional groups if specified and add the user to them
    if [[ -n "$groups" ]]; then
        for group in $groups; do
            if ! getent group "$group" &>/dev/null; then
                if ! sudo groupadd "$group" 2>>$LOG_FILE; then
                    echo "Failed to create group $group." | tee -a $LOG_FILE
                    return 1
                fi
            fi
            if ! sudo usermod -aG "$group" "$user" 2>>$LOG_FILE; then
                echo "Failed to add user $user to group $group." | tee -a $LOG_FILE
                return 1
            fi
        done
    fi

    # Generate random password
    local password
    password=$(generate_password)
    if ! echo "$user:$password" | sudo chpasswd; then
        echo "Failed to set password for user $user." | tee -a $LOG_FILE
        return 1
    fi

    # Store password securely
    echo "$user:$password" >>$PASSWORD_FILE

    # Set permissions for user's home directory
    if ! sudo chmod 700 "/home/$user"; then
        echo "Failed to set permissions for home directory of user $user." | tee -a $LOG_FILE
        return 1
    fi

    # Log the user creation
    echo "Created user $user with groups: $groups" | tee -a $LOG_FILE
}


# Read file and create users
while IFS=";" read - r user groups; do
    # remove whitespaces before and after username
    user=$(echo $user | xargs) 
    # remove whitespaces before and after group name
    groups=$(echo $groups | xargs | tr ',' ' ')
    create_user $user $groups
done < "$1" 


echo "user created successfully." | tee -a $LOG_FILE
