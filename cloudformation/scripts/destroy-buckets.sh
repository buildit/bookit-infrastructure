#!/bin/bash

echo 'This script will remove empty the S3 buckets...'

# Purposely don't use '--force' to ensure people have gone through the contents
: ${PROJECT?"Need to set project name in PROJECT env var"}
: ${OWNER?"Need to set name suffix in OWNER env var"}

# Create confirmation etc:
aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}
aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}
aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}
aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.build
