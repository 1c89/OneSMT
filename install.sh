#!/bin/sh

# permitt postgres to make backup 
adduser postgres backup

# prepare backup folder
setfacl -m g:backup:rwx /mnt/backup-volume
setfacl -d -m g:backup:rwx /mnt/backup-volume

# prepare log folders
mkdir /var/log/onesmt
chown usr1cv8:grp1cv8 /var/log/onesmt
setfacl -m g:backup:rwx /var/log/onesmt
setfacl -d -m g:backup:rwx /var/log/onesmt

# remove old version
rm -R /opt/onesmt/* 

# copy files
cp -R ./bin /opt/onesmt
cp -R ./lib /opt/onesmt

# configure solution
chown -R root:root /opt/onesmt
chmod a+x /opt/onesmt/bin/onesmt.ps1
ln -s /opt/onesmt/bin/onesmt.ps1 /usr/bin/onesmt.ps1
touch /etc/onesmt.json
setfacl -m g:backup:r /etc/onesmt.json

# add crontab scheduler task
* 2 * * * /usr/bin/onesmt.ps1 ones backup --settings /etc/onesmt.json