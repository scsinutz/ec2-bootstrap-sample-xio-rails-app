An EC2 Bootstrap script that will install salt-stack in master-less mode and then install and configure sample-xio-rails-app.

It's been tested with AMI: ami-c5180880 which runs Ubuntu 14.04

Example using ec2-api-tools:

ec2-run-instances ami-c5180880 --region us-west-1 --instance-type t1.micro -key <key-pair> -group default --user-data-file ec2-bootstrap.sh

Add your email address to "EMAIL=your email address" in the script to get notified when the bootstraping is completed. Check your spam folder!
