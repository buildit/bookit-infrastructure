#!/bin/bash

echo 'Please fill in the config settings to store in your .make'
echo
read -p 'Domain: ' domain
read -p 'Your e-mail: ' email
read -p 'Environment (tst, dev, stg, prd): ' env
read -p 'AWS SSH keyname: ' keyname
read -p 'Owner of riglet: ' owner
read -p 'AWS Profile: ' profile
read -p 'Project: ' project
read -p 'Repository Name: ' repo
read -p 'Repository Branch: ' repo_branch
read -p 'Repository OAuth token: ' repo_token
read -p 'AWS region: ' region
echo

cat << EOF > .make
DOMAIN = ${domain}
EMAIL = ${email}
ENV = ${env}
KEY_NAME = ${keyname}
OWNER = ${owner}
PROFILE = ${profile}
PROJECT = ${project}
REPO = ${repo}
REPO_BRANCH = ${repo_branch}
REPO_TOKEN = ${repo_token}
REGION = ${region}
EOF

echo 'Saved .make!'
echo
