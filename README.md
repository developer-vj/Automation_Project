# Automation_Project
 This repository will host automation script


 # criteria-1  Script updates the package information
 ## update the package details
 sudo apt update -y

 ##root user
 sudo su
 apt-get update

 # criteria-2 Script ensures that the HTTP Apache server is installed
 ##Script checks whether the HTTP Apache server is already installed. If not present, then it installs the server
 apache2= dpkg -l | grep apache2
 if [[ $apache2 != "" ]]; then
   echo "Apache2 already installed"
 else apt-get install apache2 -y
 fi

 # Criteria-3 Script ensures that HTTP Apache server is running
 ## Script checks whether the Apache server is running or not. If it is not running, then it starts the server
 servstat=$(service apache2 status)
 if [[ $servstat == *"active (running)"* ]]; then
   echo "Apache server is running"
 else sudo service apache2 start
 fi

 # Criteria-4 Script ensures that HTTP Apache service is enabled
 ## Script ensures that the server runs on restart/reboot, I.e., it checks whether the service is enabled or not. It enables the service if not enabled.
 apache_enabled= $(systemctl status apache2)
 if [[ $apache_enabled == *"active (running)"* ]]; then
   echo "apoache2  service in  enabled"
 else systemctl enable apache2.service
 fi


 # Criteria-5 Archiving logs to S3
 ## Defining the timestamp and converting all the logs file into a single tar and then copying the same tar to S3 on AWS
 timestamp=$(date '+%d%m%Y-%H%M%S')
 sudo tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2
 aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3-bucket}/${myname}-httpd-logs-${timestamp}.tar
