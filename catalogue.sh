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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling module" 

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling required module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop
if [ id -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding user roboshop"
else
    echo -e "User already exists $Y SKIPPING.....$N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue application"

cd /app 
VALIDATE $? "Change the directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip catalogue application"

cd /app 
VALIDATE $? "Change the directory"

npm install 
VALIDATE $? "Install dependencies" &>>$LOG_FILE

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy the service file"

systemctl daemon-reload
VALIDATE $? "Reload the service"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable the service"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Start the service"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy the mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install the MongoDB client"

mongosh --host mongodb.durgadevops.fun </app/db/master-data.js
VALIDATE $? "Load the data"

