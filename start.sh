#!/bin/bash
set -e 
s3fs $S3_BUCKET_NAME $S3_MOUNT_DIRECTORY nonempty
mkdir -p /mnt/s3/rcs/running
mkdir -p /mnt/s3/rcs/ttyrecs
cd /dcss/crawl-ref/source 
#&& ./crawl
python3 ./webserver/server.py
