#!/usr/bin/env bash

#Logging of output
exec > >(tee /var/log/user-data.log >/dev/console) 2>&1

#installation of the salt-sack repo and salt-minion package
apt-get install python-software-properties -y
apt-get install software-properties-common -y
add-apt-repository ppa:saltstack/salt -y
apt-get update -y
apt-get install salt-minion -y

#set salt-minion run masterless
sed -i /etc/salt/minion -e 's/#file_client: remote/file_client: local/'

#install git
apt-get install git -y

#clone salt states
git clone https://github.com/scsinutz/salt-stack-sample-xio-rails-app.git /srv/

#remove dist version of Ruby (1.9.x) since we'll be installing Ruby 2.1 with rvm
apt-get purge ruby -y

#install curl 
apt-get install curl -y

#set hostname and hosts file
DOMAIN=xio.local
HOSTNAME=webapp
IPV4=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

/bin/hostname $HOSTNAME
echo $HOSTNAME > /etc/hostname

cat<<EOF > /etc/hosts
# This file was created by ec2-bootstrap.sh
127.0.0.1 localhost
$IPV4 $HOSTNAME.$DOMAIN $HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
EOF

debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME.$DOMAIN"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install postfix -y

#bootstrap application via salt
salt-call state.sls bootstrap_application

#send email to notify bootstrap is complete
UPTIME=$(uptime)
SECGROUP=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/security-groups/)
INTYPE=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-type)
INID=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
IPV4=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
EMAIL="<your email address>"

/usr/sbin/sendmail -oi -t -f $EMAIL <<EOM
From: $EMAIL
To: $EMAIL
Subject:[$HOSTNAME.$DOMAIN] ec2-bootstrap complete.

This email message was generated on the following EC2 instance:

    Instance ID:	$INID
    Instance Type:	$INTYPE
    Security Group: 	$SECGROUP
    Region:		$REGION
    Uptime:		$UPTIME
    IP:			$IPV4

    Bootstrap script output is logged to /var/log/user-data.log

EOM

