#!/bin/bash
#
# Frustrating trying to get the output till I found this: https://aws.amazon.com/premiumsupport/knowledge-center/ec2-linux-log-user-data/
#
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sudo /usr/bin/yum install --assumeyes --noplugins --cacheonly https://s3.eu-west-2.amazonaws.com/amazon-ssm-eu-west-2/latest/linux_amd64/amazon-ssm-agent.rpm 