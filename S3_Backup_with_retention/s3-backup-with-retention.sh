#!/bin/bash

### Variable decleration. ###
s3_bucket=s3://backups-ovh-server
d=`date +"%Y-%m-%d"`
dates=($(s3cmd ls $s3_bucket/ | cut -d'/' -f4))
limit_sec=`date -d"30 days ago" +%s`
today=`date +"%Y-%m-%d"`
today_sec=`date -d"$today 00:00:00" +%s`

echo '' >> /var/log/s3-backup.log
echo '############ BACKUPS STARTS FOR THE DAY '$d' ###############' >> /var/log/s3-backup.log
cd /var/
tar -cf /opt1/www_backup_$d.tar.gz www && echo 'File backup completed.' >> /var/log/s3-backup.log

#### Mysql ###
mkdir /opt1/databases-backup
for i in `cat /root/.db-list.txt`; do
mysqldump $i > /opt1/databases-backup/$i-$d.sql && echo 'DB backup '$i' completed.' >> /var/log/s3-backup.log
done
cd /opt1/ 
tar -cf  databases_backup_$d.tar.gz databases-backup && echo 'DB archive completed.' >> /var/log/s3-backup.log

### Uploading to S3 ###

echo 'Uploading backups to S3...' >> /var/log/s3-backup.log
s3cmd put /opt1/www_backup_$d.tar.gz $s3_bucket/$d/ >> /var/log/s3-backup.log
s3cmd put /opt1/databases_backup_$d.tar.gz $s3_bucket/$d/ >> /var/log/s3-backup.log
rm -rvf  /opt1/www_backup_$d.tar.gz /opt1/databases_backup_$d.tar.gz  /opt1/databases-backup >> /var/log/s3-backup.log
echo '############ BACKUPS SCRIPT ENDED FOR THE DAY '$d' ###############' >> /var/log/s3-backup.log

### Retention check ### 30days
echo 'Checking retention' >> /var/log/s3-backup.log
for i in ${dates[@]}
do

	da=$i
	dates_sec=`date -d"$da 00:00:00" +%s`
	if [ $dates_sec -le $limit_sec ]; then
		echo "Removing Directory"$i  >> /var/log/s3-backup.log
		s3cmd del -r $s3_bucket/$i
	else
		echo "NOT Removing Directory"$i  >> /var/log/s3-backup.log
		
	fi
done

