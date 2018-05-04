#!/bin/bash

echo 'Please fill in the config settings to store in your .make.'
echo 'Defaults are shown in parens.  <Enter> to accept.'
echo
read -p 'Domain ("buildit.tools"): ' domain
read -p 'AWS SSH keyname: ' keyname
read -p 'Owner of riglet: ' owner
read -p 'AWS Profile ("default"): ' profile
read -p 'Project ("bookit"): ' project
read -p 'AWS region ("us-east-1"): ' region
read -p 'AWS Certificate Manager GUID ("buildit.tools cert GUID"): ' domain_guid
echo

cat << EOF > .make
DOMAIN = ${domain:-buildit.tools}
KEY_NAME = ${keyname}
OWNER = ${owner}
PROFILE = ${profile:-default}
PROJECT = ${project:-bookit}
REGION = ${region:-us-east-1}
DOMAIN_CERT = ${domain_guid:-0663e927-e990-4157-aef9-7dea87faa6ec}
EOF

echo 'Saved .make!'
echo 'Please verify with "make check-env"!'
echo
