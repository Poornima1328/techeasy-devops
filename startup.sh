#!/bin/bash
apt update -y
apt install -y awscli

# App logs
echo "App started" > /tmp/app.log

# Upload to S3
aws s3 cp /tmp/app.log s3://${bucket_name}/app/logs/
aws s3 cp /var/log/messages s3://${bucket_name}/ec2-logs/

shutdown -h +15
