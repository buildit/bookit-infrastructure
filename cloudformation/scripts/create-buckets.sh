#!/bin/bash

echo "Create Build Execution Environment Artifacts S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.build"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build" --region "${REGION}" 2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.build --region "${REGION}" # Build artifacts, etc
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build" --versioning-configuration Status=Enabled --region "${REGION}"

echo "Create Foundation S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}" --region "${REGION}"  2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}  --region "${REGION}" # Foundation configs
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"

echo "Create App S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}" --region "${REGION}" 2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV} --region "${REGION}" # Storage for InfraDev
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"

echo "Create Build Support Artifacts S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}" --region "${REGION}" 2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV} --region "${REGION}" # Build artifacts, etc
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"
