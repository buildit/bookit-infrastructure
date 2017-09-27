#!/bin/bash

echo 'Creating build user...'
echo

if [[ -z $1 || -z $2 ]] ; then
    echo 'Missing command line arguments'
    echo 'USAGE: create-build-user.sh <Owner> <Project>'
    exit 1
fi

OWNER=$1
PROJECT=$2
USER_NAME="${OWNER}-${PROJECT}"
aws iam create-user --user-name "${USER_NAME}" > created-user-out-credentials.json
aws iam create-access-key --user-name "${USER_NAME}" >> created-user-out-credentials.json
aws iam put-user-policy --user-name "${USER_NAME}" --policy-name Ecr --policy-document file://iam/EcrPolicy.json
aws iam put-user-policy --user-name "${USER_NAME}" --policy-name Ecs --policy-document file://iam/EcsPolicy.json
aws iam put-user-policy --user-name "${USER_NAME}" --policy-name S3  --policy-document file://iam/S3Policy.json
aws iam put-user-policy --user-name "${USER_NAME}" --policy-name Ssm --policy-document file://iam/SsmPolicy.json

echo
echo "Look in created-user-out-credentials.json for generated values."
