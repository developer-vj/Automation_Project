#!/bin/bash
## tag- Automation-v0.1- statrts here
#Defining constant variable
s3-bucket="upgrad-vijendra"
myname="Vijendra"

## criteria-1  Script updates the package information
#update the package details
sudo apt update -y

#root user
sudo su
apt-get update

## criteria-2 Script ensures that the HTTP Apache server is installed
#Script checks whether the HTTP Apache server is already installed. If not present, then it installs the server
apache2= dpkg -l | grep apache2
if [[ $apache2 != "" ]]; then
  echo "Apache2 already installed"
else apt-get install apache2 -y
fi

## Criteria-3 Script ensures that HTTP Apache server is running
#Script checks whether the Apache server is running or not. If it is not running, then it starts the server
servstat=$(service apache2 status)
if [[ $servstat == *"active (running)"* ]]; then
  echo "Apache server is running"
else sudo service apache2 start
fi

## Criteria-4 Script ensures that HTTP Apache service is enabled
#Script ensures that the server runs on restart/reboot, I.e., it checks whether the service is enabled or not. It enables the service if not enabled.
apache_enabled= $(systemctl status apache2)
if [[ $apache_enabled == *"active (running)"* ]]; then
  echo "apoache2  service in  enabled"
else systemctl enable apache2.service
fi

#found alternate way to do same
#   vi /etc/init.d/apache2 (edit it as shown below)
#   chmod 755 /etc/init.d/apache2
#   chkconfig --add apache2
#   chkconfig --list apache2 (to verify that it worked)

# apache2        Startup script for the Apache HTTP Server
#
#   chkconfig: 3 85 15
# description: Apache is a World Wide Web server.  It is used to serve \
#              HTML files and CGI.
# below script needs  to be added
#   /usr/local/apache2/bin/apachectl $@


## Criteria-5 Archiving logs to S3
#Defining the timestamp and converting all the logs file into a single tar and then copying the same tar to S3 on AWS
timestamp=$(date '+%d%m%Y-%H%M%S')
sudo tar -cvf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2
aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3-bucket}/${myname}-httpd-logs-${timestamp}.tar

## tag- Automation-v0.1- ends here


## tag- Automation-v0.2- starts here

## Criteria-2  Maintain a record of archives (.tar) in  Inventory.html
#saving the log files info in a temporary file logs.txt
log_archive="/tmp/logs.txt"
size=$( echo $(du -sh /tmp/${myname}-httpd-logs-${timestamp}.tar) | awk '{print $1}')
echo "httpd-logs ${timestamp} tar $size" >> $log_archive


#create inventory.html if not available
if [ -f /var/www/html/inventory.html ];
then
    echo "inventory.html already exist"
else
    echo "inventory.html does not exist"
    touch /var/www/html/inventory.html
    cat > /var/www/html/inventory.html << EOF
      <!DOCTYPE html>
      <html>
      <head>
      <style>
      table {
        font-family: arial, sans-serif;
        border-collapse: collapse;
        width: 100%;
        }

        td, th {
          border: 1px solid #dddddd;
          text-align: left;
          padding: 8px;
        }

        tr:nth-child(even) {
          background-color: #dddddd;
        }
        </style>
        </head>
        <body>
        <h2>LOGs Table</h2>
        <table>
        <tr>
          <th>Log Type</th>
          <th>Time Created</th>
          <th>Type</th>
          <th>Size</th>
        </tr>
        <!-- PLACEHOLDER -->
        </table>

        </body>
  </html>
EOF
fi

# if temporary files contains information append the information data of logs to inventory.html
if [ -f $log_archive ];
then
  #building the rows content from log.txt file and appending the PLACEHOLDER at the end
  data=$(cat logs.txt | awk '{print "<tr>\\n<td>"$1"<\\/td>\\n<td>"$2"<\\/td>\\n<td>"$3"<\\/td>\\n<td>"$4"<\\/td>\\n<\\/tr>\\n"}')"<\!-- PLACEHOLDER -->/"
  #tr -d '\n' replaces the next line space and then replacing the PLACEHOLDER with  $data values in inventory.html
  sed -I ""  "s/<\!\-\- PLACEHOLDER \-\->/$(tr -d '\n' <<<$data)" /var/www/html/inventory.html
else
  echo "Logs not updated"
fi

#delete the temporary file logs.txt
rm $log_archive

#clone the project in root folder
mkdir /root/Automation_Project
git clone https://github.com/developer-vj/Automation_Project.git /root/Automation_Project

##  criteria -1 Run a Cron Job if it does not exist
#create a cron job to shedule script at 12PM every day,
if [ -f /etc/cron.d/automation ];
then
    echo "cron exist"
else
  sudo echo "0 12 * * * /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
  chmod +x /root/Automation_Project/automation.sh
fi

## tag- Automation-v0.2- ends here
