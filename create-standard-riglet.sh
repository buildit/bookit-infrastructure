#!/usr/bin/env bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

cat .make

printf  "\n${YELLOW}This command creates a full riglet based on the environment described above.${NC}\n"
read -p "Are you sure you want to proceed?  " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Y" | make create-foundation ENV=integration
  echo "Y" | make create-compute ENV=integration
  echo "Y" | make create-foundation ENV=staging
  echo "Y" | make create-compute ENV=staging
  echo "Y" | make create-foundation ENV=production
  echo "Y" | make create-compute ENV=production

  echo "Y" | make create-build REPO=bookit-api REPO_BRANCH=master CONTAINER_PORT=8080 LISTENER_RULE_PRIORITY=10
fi
