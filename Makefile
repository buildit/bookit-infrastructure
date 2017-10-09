include .make

export DOMAIN ?= example.tld
export KEY_NAME ?= ""
export OWNER ?= rig-test-bucket
export PROFILE ?= default
export PROJECT ?= projectname
export REGION ?= us-east-1
export PREFIX ?= ${OWNER}

export AWS_PROFILE=${PROFILE}
export AWS_REGION=${REGION}


## Create dependency S3 buckets
# Used for storage of Foundation configs, InfraDev storage and Build artifacts
# These are created outside Terraform since it'll store sensitive contents!
# When completely empty, can be destroyed with `make destroy-deps`
deps:
	@echo "Create Build Artifacts S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.build"
	@aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build" --region "${REGION}" 2>/dev/null || \
		aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.build --region "${REGION}" # Build artifacts, etc
	@aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build" --versioning-configuration Status=Enabled --region "${REGION}"

	@echo "Create Foundation S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}"
	@aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}" --region "${REGION}"  2>/dev/null || \
		aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}  --region "${REGION}" # Foundation configs
	@aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"

	@echo "Create Compute S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.compute-ecs.${ENV}"
	@aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.compute-ecs.${ENV}" --region "${REGION}"  2>/dev/null || \
		aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.compute-ecs.${ENV}  --region "${REGION}" # Foundation configs
	@aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.compute-ecs.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"

	@echo "Create App S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}"
	@aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}" --region "${REGION}" 2>/dev/null || \
		aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV} --region "${REGION}" # Storage for InfraDev
	@aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"

	# @echo "Create Build Support S3 bucket: rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}"
	# @aws s3api head-bucket --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}" --region "${REGION}" 2>/dev/null || \
	# 	aws s3 mb s3://rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV} --region "${REGION}" # Build artifacts, etc
	# @aws s3api put-bucket-versioning --bucket "rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}" --versioning-configuration Status=Enabled --region "${REGION}"

# Destroy dependency S3 buckets, only destroy if empty
delete-deps:
	@aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}
	@aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.compute-ecs.${ENV}
	@aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}
	# @aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}
	@aws s3 rb --force s3://rig.${OWNER}.${PROJECT}.${REGION}.build

## Creates Foundation and Build

## Creates a new CF stack
create-foundation: deps upload-templates
	@aws cloudformation create-stack --stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" \
                --region ${REGION} \
		--template-body "file://cloudformation/foundation/main.yaml" \
		--disable-rollback \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=Environment,ParameterValue=${ENV}" \
			"ParameterKey=FoundationBucket,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}" \
			"ParameterKey=ProjectName,ParameterValue=${PROJECT}" \
			"ParameterKey=PublicDomainName,ParameterValue=${DOMAIN}" \
			"ParameterKey=Region,ParameterValue=${REGION}" \
		--tags \
			"Key=Environment,Value=${ENV}" \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-create-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" --region ${REGION}

## Create new CF compute stack
create-compute: upload-compute
	@aws cloudformation create-stack --stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" \
                --region ${REGION} \
                --disable-rollback \
		--template-body "file://cloudformation/compute-ecs/main.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=FoundationStackName,ParameterValue=${OWNER}-${PROJECT}-${ENV}-foundation" \
			"ParameterKey=SshKeyName,ParameterValue=${KEY_NAME}" \
			"ParameterKey=InstanceType,ParameterValue=t2.small" \
		--tags \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-create-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" --region ${REGION}

## Create new CF environment stacks
create-environment: create-foundation create-compute

## Create new CF Build pipeline stack
create-build: upload-build
	@aws cloudformation create-stack --stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}" \
                --region ${REGION} \
                --disable-rollback \
		--template-body "file://cloudformation/build/deployment-pipeline.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=AppStackName,ParameterValue=${OWNER}-${PROJECT}" \
			"ParameterKey=PublicDomainName,ParameterValue=${DOMAIN}" \
			"ParameterKey=InfraDevBucketBase,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.app" \
			"ParameterKey=BuildArtifactsBucket,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.build" \
			"ParameterKey=GitHubRepo,ParameterValue=${REPO}" \
			"ParameterKey=GitHubBranch,ParameterValue=${REPO_BRANCH}" \
			"ParameterKey=GitHubToken,ParameterValue=${REPO_TOKEN}" \
			"ParameterKey=ApplicationName,ParameterValue=${REPO}" \
			"ParameterKey=Prefix,ParameterValue=${PREFIX}" \
			"ParameterKey=ContainerPort,ParameterValue=${CONTAINER_PORT}" \
			"ParameterKey=ListenerRulePriority,ParameterValue=${LISTENER_RULE_PRIORITY}" \
		--tags \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-create-complete --stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}" --region ${REGION}

## Create new CF app stack
create-app: deps upload-app
	@aws cloudformation create-stack --stack-name "${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}" \
                --region ${REGION} \
                --disable-rollback \
		--template-body "file://cloudformation/app/app.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=Environment,ParameterValue=${ENV}" \
			"ParameterKey=FoundationStackName,ParameterValue=${OWNER}-${PROJECT}-${ENV}-foundation" \
			"ParameterKey=InfraDevBucket,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}" \
			"ParameterKey=PublicDomainName,ParameterValue=${DOMAIN}" \
			"ParameterKey=Repository,ParameterValue=${OWNER}-${PROJECT}-${REPO}-${REPO_BRANCH}-ecr-repo" \
			"ParameterKey=ApplicationName,ParameterValue=${REPO}" \
			"ParameterKey=ContainerPort,ParameterValue=${CONTAINER_PORT}" \
			"ParameterKey=ListenerRulePriority,ParameterValue=${LISTENER_RULE_PRIORITY}" \
		--tags \
			"Key=Environment,Value=${ENV}" \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-create-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}" --region ${REGION}

## Updates existing Foundation CF stack
update-foundation: upload-templates
	@aws cloudformation update-stack --stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" \
                --region ${REGION} \
		--template-body "file://cloudformation/foundation/main.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=Environment,ParameterValue=${ENV}" \
			"ParameterKey=FoundationBucket,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}" \
			"ParameterKey=ProjectName,ParameterValue=${PROJECT}" \
			"ParameterKey=PublicDomainName,ParameterValue=${DOMAIN}" \
			"ParameterKey=Region,ParameterValue=${REGION}" \
			"ParameterKey=SshKeyName,ParameterValue=${KEY_NAME}" \
		--tags \
			"Key=Environment,Value=${ENV}" \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-update-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" --region ${REGION}

## Update CF compute stack
update-compute: upload-compute
	@aws cloudformation update-stack --stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" \
                --region ${REGION} \
		--template-body "file://cloudformation/compute-ecs/main.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=FoundationStackName,ParameterValue=${OWNER}-${PROJECT}-${ENV}-foundation" \
			"ParameterKey=SshKeyName,ParameterValue=${KEY_NAME}" \
			"ParameterKey=InstanceType,ParameterValue=t2.small" \
		--tags \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-update-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" --region ${REGION}

## Update CF environment stacks
update-environment: update-foundation update-compute

## Update existing Build Pipeline CF Stack
update-build: upload-build
	@aws cloudformation update-stack --stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}" \
                --region ${REGION} \
		--template-body "file://cloudformation/build/deployment-pipeline.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=AppStackName,ParameterValue=${OWNER}-${PROJECT}" \
			"ParameterKey=PublicDomainName,ParameterValue=${DOMAIN}" \
			"ParameterKey=InfraDevBucketBase,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.app" \
			"ParameterKey=BuildArtifactsBucket,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.build" \
			"ParameterKey=GitHubRepo,ParameterValue=${REPO}" \
			"ParameterKey=GitHubBranch,ParameterValue=${REPO_BRANCH}" \
			"ParameterKey=GitHubToken,ParameterValue=${REPO_TOKEN}" \
			"ParameterKey=ApplicationName,ParameterValue=${REPO}" \
			"ParameterKey=Prefix,ParameterValue=${OWNER}" \
			"ParameterKey=ContainerPort,ParameterValue=${CONTAINER_PORT}" \
			"ParameterKey=ListenerRulePriority,ParameterValue=${LISTENER_RULE_PRIORITY}" \
		--tags \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-update-complete --stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH} --region ${REGION}"

## Update App CF stack
update-app: deps upload-app
	@aws cloudformation update-stack --stack-name "${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}" \
                --region ${REGION} \
		--template-body "file://cloudformation/app/app.yaml" \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters \
			"ParameterKey=Environment,ParameterValue=${ENV}" \
			"ParameterKey=FoundationStackName,ParameterValue=${OWNER}-${PROJECT}-${ENV}-foundation" \
			"ParameterKey=InfraDevBucket,ParameterValue=rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}" \
			"ParameterKey=PublicDomainName,ParameterValue=${DOMAIN}" \
			"ParameterKey=Repository,ParameterValue=${OWNER}-${PROJECT}-${REPO}-${REPO_BRANCH}-ecr-repo" \
			"ParameterKey=ApplicationName,ParameterValue=${REPO}" \
			"ParameterKey=ContainerPort,ParameterValue=${CONTAINER_PORT}" \
			"ParameterKey=ListenerRulePriority,ParameterValue=${LISTENER_RULE_PRIORITY}" \
		--tags \
			"Key=Environment,Value=${ENV}" \
			"Key=Owner,Value=${OWNER}" \
			"Key=Project,Value=${PROJECT}"
	@aws cloudformation wait stack-update-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-app" --region ${REGION}

## Print Foundation stack's status
status-foundation:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" \
		--query "Stacks[][StackStatus] | []" | jq

## Print Foundation stack's outputs
outputs-foundation:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" \
		--query "Stacks[][Outputs] | []" | jq

## Print Compute stack's status
status-compute:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" \
		--query "Stacks[][StackStatus] | []" | jq

## Print Compute stack's outputs
outputs-compute:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" \
		--query "Stacks[][Outputs] | []" | jq

## Print Environment stacks' status
status-environment: status-foundation status-compute

## Print Environment stacks' output
outputs-environment: outputs-foundation outputs-compute

## Print build pipeline stack's status
status-build:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}" \
		--query "Stacks[][StackStatus] | []" | jq


## Print build pipeline stack's outputs
outputs-build:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}" \
		--query "Stacks[][Outputs] | []" | jq

## Print app stack's status
status-app:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}" \
		--query "Stacks[][StackStatus] | []" | jq

## Print app stack's outputs
outputs-app:
	@aws cloudformation describe-stacks \
                --region ${REGION} \
		--stack-name "$${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}" \
		--query "Stacks[][Outputs] | []" | jq


## Deletes the Foundation CF stack
delete-foundation:
	@if ${MAKE} .prompt-yesno message="Are you sure you wish to delete the ${ENV} Foundation Stack?"; then \
		aws cloudformation delete-stack --region ${REGION} --stack-name "${OWNER}-${PROJECT}-${ENV}-foundation"; \
		aws cloudformation wait stack-delete-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-foundation" --region ${REGION}; \
	fi

## Deletes the Compute CF stack
delete-compute:
	@if ${MAKE} .prompt-yesno message="Are you sure you wish to delete the ${ENV} Compute Stack?"; then \
		aws cloudformation delete-stack --region ${REGION} --stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs"; \
		aws cloudformation wait stack-delete-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-compute-ecs" --region ${REGION}; \
	fi

## Deletes the Environment CF stacks
delete-environment: delete-compute delete-foundation

## Deletes the build pipeline CF stack
delete-build:
	$(eval export ECR_REPO = $(shell echo "${OWNER}-${PROJECT}-${REPO}-${REPO_BRANCH}-ecr-repo"))
	$(eval export ECR_COUNT = $(shell aws ecr list-images --repository-name "${ECR_REPO}" | jq -r '.imageIds | length | select (.!=0|0)'))
	@if [[ "${ECR_COUNT}" != "0" ]]; then \
		echo "${.RED}Can't delete ECS Repository '${ECR_REPO}', there are still ${ECR_COUNT} Docker images on it!${.CLEAR}"; \
		echo "${.YELLOW}[Cancelled]${.CLEAR}" && exit 1 ; \
	fi;
	@if ${MAKE} .prompt-yesno message="Are you sure you wish to delete the ${PROJECT} Pipeline Stack for repo: ${REPO} branch: ${REPO_BRANCH}?"; then \
		aws cloudformation delete-stack --region ${REGION} --stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}"; \
		aws cloudformation wait stack-delete-complete --stack-name "${OWNER}-${PROJECT}-build-${REPO}-${REPO_BRANCH}" --region ${REGION}; \
	fi

## Deletes the app CF stack
delete-app:
	@if ${MAKE} .prompt-yesno message="Are you sure you wish to delete the App Stack for environment: ${ENV} repo: ${REPO} branch: ${REPO_BRANCH}?"; then \
		aws cloudformation delete-stack --region ${REGION} --stack-name "${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}"; \
		aws cloudformation wait stack-delete-complete --stack-name "${OWNER}-${PROJECT}-${ENV}-app-${REPO}-${REPO_BRANCH}" --region ${REGION}; \
	fi

upload-templates: upload-foundation upload-app

## Upload CF Templates to S3
# Uploads foundation templates to the Foundation bucket
upload-foundation:
	@aws s3 cp --recursive cloudformation/foundation/ s3://rig.${OWNER}.${PROJECT}.${REGION}.foundation.${ENV}/templates/

## Upload CF Templates for project
# Note that these templates will be stored in your InfraDev Project **shared** bucket:
upload-app: upload-app-deployment
	@aws s3 cp --recursive cloudformation/app/ s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}/templates/
	@pwd=$(shell pwd)
	@cd cloudformation/app/ && zip templates.zip *.yaml
	@cd ${pwd}
	@aws s3 cp cloudformation/app/templates.zip s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}/templates/
	@rm -rf cloudformation/app/templates.zip
	@aws s3 cp cloudformation/app/app.yaml s3://rig.${OWNER}.${PROJECT}.${REGION}.app.${ENV}/templates/

## Upload app-deployment scripts to S3
# Uploads the build support scripts to the build-support bucket.  These scripts can be used by external
# build tools (Jenkins, Travis, etc.) to push images to ECR, deploy to ECS, etc.
upload-app-deployment:
#	@aws s3 cp --recursive app-deployment/ s3://rig.${OWNER}.${PROJECT}.${REGION}.build-support.${ENV}/app-deployment/

## Upload Compute ECS Templates
upload-compute:
	@aws s3 cp --recursive cloudformation/compute-ecs/ s3://rig.${OWNER}.${PROJECT}.${REGION}.compute-ecs.${ENV}/templates/

## Upload Build CF Templates
upload-build:
	@aws s3 cp --recursive cloudformation/build/ s3://rig.${OWNER}.${PROJECT}.${REGION}.build/templates/

check-env:
ifndef OWNER
	$(error OWNER is undefined, should be in file .make)
endif
ifndef DOMAIN
	$(error DOMAIN is undefined, should be in file .make)
endif
ifndef KEY_NAME
	$(error KEY_NAME is undefined, should be in file .make)
endif
ifndef PROFILE
	$(error PROFILE is undefined, should be in file .make)
endif
ifndef PROJECT
	$(error PROJECT is undefined, should be in file .make)
endif
ifndef REGION
	$(error REGION is undefined, should be in file .make)
endif
ifndef REPO_TOKEN
	$(error REPO_TOKEN is undefined, should be in file .make)
endif
	@echo "All required ENV vars set"

## Print this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		${MAKEFILE_LIST}


.CLEAR=\x1b[0m
.BOLD=\x1b[01m
.RED=\x1b[31;01m
.GREEN=\x1b[32;01m
.YELLOW=\x1b[33;01m

# Re-usable target for yes no prompt. Usage: make .prompt-yesno message="Is it yes or no?"
# Will exit with error if not yes
.prompt-yesno:
	$(eval export RESPONSE="${shell read -t30 -n1 -p "${message} [Yy]: " && echo "$$REPLY" | tr -d '[:space:]'}")
	@case ${RESPONSE} in [Yy]) \
			echo "\n${.GREEN}[Continuing]${.CLEAR}" ;; \
		*) \
			echo "\n${.YELLOW}[Cancelled]${.CLEAR}" && exit 1 ;; \
	esac


.make:
	@touch .make
	@scripts/build-dotmake.sh

.DEFAULT_GOAL := help
.PHONY: help
.PHONY: deps check-env get-ubuntu-ami .prompt-yesno
