#!/bin/bash

echo 'Please fill in the config settings to store in your .make'
echo
read -p 'Domain: ' domain
read -p 'AWS SSH keyname: ' keyname
read -p 'Owner of riglet: ' owner
read -p 'AWS Profile: ' profile
read -p 'Project: ' project
read -p 'Repository OAuth token: ' repo_token
read -p 'AWS region: ' region
echo

cat << EOF > .make
DOMAIN = ${domain}
KEY_NAME = ${keyname}
OWNER = ${owner}
PROFILE = ${profile}
PROJECT = ${project}
REPO_TOKEN = ${repo_token}
REGION = ${region}
EOF

echo 'Saved .make!'
echo
