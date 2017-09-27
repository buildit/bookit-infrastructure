#!/usr/bin/env bash

# NOTE: assumes awscli is already installed

REPO_NAME=${ECS_REPO}
echo "The AWS region is ${AWS_DEFAULT_REGION}"

EXISTING_REPO=$(aws ecr describe-repositories --repository-names ${REPO_NAME} --output text 2>/dev/null)
REPO_EXISTS=$(echo $?)

if [[ ${REPO_EXISTS} == 0 ]]; then
  echo "Repo already exists ... skipping creation"
  REPO=$(echo ${EXISTING_REPO} | cut -f 6 -d ' ')
else
  echo "Creating repo"
  REPO=$(aws ecr create-repository --repository-name ${REPO_NAME} --output text | cut -f 6)
  echo "Created repo:  $REPO"
fi

#eval $(aws ecr get-login)
#use below locally when above fails
eval $(aws ecr get-login | sed 's/-e none//')

echo "Preparing to tag, repo:  ${REPO},  sha: ${COMMIT_SHA}"
docker build -t "${REPO}:${COMMIT_SHA}" -t "${REPO}:latest" .
docker push "${REPO}:${COMMIT_SHA}"
docker push "${REPO}:latest"