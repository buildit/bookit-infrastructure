#!/bin/bash

echo "Create Build Execution Environment Artifacts S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.build"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build" --region "${REGION}" 2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.build --region "${REGION}" # Build artifacts, etc
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build" --versioning-configuration Status=Enabled --region "${REGION}"

echo "Create Foundation S3 bucket: rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.foundation"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.foundation" --region "${REGION}"  2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.foundation  --region "${REGION}" # Foundation configs
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.foundation" --versioning-configuration Status=Enabled --region "${REGION}"

echo "Create App S3 bucket: rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.app"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.app" --region "${REGION}" 2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.app --region "${REGION}" # Storage for InfraDev
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.app" --versioning-configuration Status=Enabled --region "${REGION}"

echo "Create Build Support Artifacts S3 bucket: rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.build-support"
aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.build-support" --region "${REGION}" 2>/dev/null ||
  aws s3 mb s3://rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.build-support --region "${REGION}" # Build artifacts, etc
aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${ENV}.${REGION}.build-support" --versioning-configuration Status=Enabled --region "${REGION}"
