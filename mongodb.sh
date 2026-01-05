#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-script"
LOG_FILE_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$LOG_FILE_NAME.log"

mkdir -p $LOG_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR:: Run the script with root privilege $N"
    exit 1
fi

# Function - will not run unless until we call it explicitly
VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R ERROR:: $2 FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y 
VALIDATE $? "Installing Mongo DB"

systemctl enable mongod 
VALIDATE $? "Enabling Mongo DB"

systemctl start mongod 
VALIDATE $? "Started Mongo DB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted the MongoDB"