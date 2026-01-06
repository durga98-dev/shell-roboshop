#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/shell-script"
LOG_FILE_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$LOG_FILE_NAME.log"
CURRENT_PATH=$(echo $PWD)

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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling default module Redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling module Redis 7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

sed -i -e '/S/127.0.0.1/0.0.0.0/G' -e '/protected-mode/ c protected-mode no'/etc/redis/redis.conf
VALIDATE $? "Allowing remote connections to Redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling service Redis"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Started service Redis"