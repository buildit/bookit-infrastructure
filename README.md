# AWS The Rig

This setup will create a CloudFormation, AWS CodePipeline/CodeBuild/CodeDeploy powered Rig on AWS.

## Setup

### Dependencies

For using this repo you'll need:

* AWS CLI, and credentials working: `brew install awscli && aws configure`
* Setup `.make` for local settings

This can either be done by copying settings from the template `.make.example`
and save in a new file `.make`:

```
DOMAIN = <Domain to use for Foundation>
EMAIL = <User contact e-mail>
KEY_NAME = <EC2 SSH key name>
OWNER = <The owner of the stack, either personal or corporate>
PROFILE = <AWS Profile Name>
PROJECT = <Project Name>
REGION = <AWS Region>
REPO_TOKEN = <Github OAuth or Personal Access Token>
```

Or also done interactively through `make .make`.

Confirm everything is valid with `make check-env`

## Makefile Targets

* Run `make create-foundation ENV=integration` to start an AWS Bare Rig Foundation Stack.  This is syncrhonous and will wait until the stack is created (or fails).  This is the Stack that will be shared by all management and services in an AWS Region.
  * The Build Pipeline requires an "integration" environment.
* Run `make status-foundation ENV=integration` to check status of the stack. (Should be `CREATE_COMPLETE`)
* Check the outputs as well with `make outputs-foundation ENV=integration`
* Run `make create-build-pipeline REPO=<repo_name> REPO_BRANCH=<branch> CONTAINER_PORT=<port> LISTENER_RULE_PRIORITY=<priority>`, same options for status: `make status-build-pipeline` and outputs `make outputs-build-pipeline`
  * REPO is the repo that hangs off buildit organization (e.g "bookit-api")
  * CONTAINER_PORT is the port that the application exposes (e.g. 8080)
  * LISTENER_RULE_PRIORITY is the priority of the the rule that gets created in the ALB.  While these won't ever conflict, ALB requires a unique number across all apps that share the ALB.

To delete everything, in order:

* Run `make delete-app ENV=<environment> REPO=<repo_name> REPO_BRANCH=<branch>` to delete the App stacks.
* Run `make delete-build-pipeline REPO=<repo_name> REPO_BRANCH=<branch>` to delete the Pipline stack.
* Run `make delete-foundation ENV=<environment>` to delete the Foundation stack.
* Run `make delete-deps ENV=<environment>` to delete the required S3 buckets.

## Architectural Decisions

We are documenting our decisions [here](../master/docs/architecture/decisions)
