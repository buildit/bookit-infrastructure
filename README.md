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
KEY_NAME = <EC2 SSH key name>
OWNER = <The owner of the stack, either personal or corporate>
PROFILE = <AWS Profile Name>
PROJECT = <Project Name>
REGION = <AWS Region>
REPO_TOKEN = <Github OAuth or Personal Access Token>
```

Or also done interactively through `make .make`.

For the "real" bookit riglet:
```
DOMAIN = buildit.tools
KEY_NAME = buildit-bookit-ssh-keypair
OWNER = buildit
PROFILE = default
PROJECT = bookit
REPO_TOKEN = <ask a team member>
REGION = us-east-1
```

Confirm everything is valid with `make check-env`

## Makefile Targets

* Run `make create-foundation ENV=integration` to start an AWS Bare Rig Foundation Stack.  This is syncrhonous and will wait until the stack is created (or fails).  This is the Stack that will be shared by all management and services in an AWS Region.
  * The Build Pipeline requires an "integration" environment.
* Run `make status-foundation ENV=integration` to check status of the stack. (Should be `CREATE_COMPLETE`)
* Check the outputs as well with `make outputs-foundation ENV=integration`
* Run `make create-foundation ENV=staging`
* Run `make create-foundation ENV=production`
* Run `make create-build-pipeline REPO=<repo_name> REPO_BRANCH=<branch> CONTAINER_PORT=<port> LISTENER_RULE_PRIORITY=<priority>`, same options for status: `make status-build-pipeline` and outputs `make outputs-build-pipeline`
  * REPO is the repo that hangs off buildit organization (e.g "bookit-api")
  * CONTAINER_PORT is the port that the application exposes (e.g. 8080)
  * LISTENER_RULE_PRIORITY is the priority of the the rule that gets created in the ALB.  While these won't ever conflict, ALB requires a unique number across all apps that share the ALB.  See [Application specifics](#application-specifics)
  * (optional) PREFIX is what goes in front of the URI of the application.  Defaults to OWNER but for the "real" riglet should be set to blank (e.g. `PREFIX=`)

To delete everything, in order:

* Run `make delete-app ENV=<environment> REPO=<repo_name> REPO_BRANCH=<branch>` to delete the App stacks.
  * if you deleted the pipeline first, you'll find you can't delete the app stacks because the role that created them is gone.  You'll have to manually delete via aws cli and the `--role-arn` override
* Run `make delete-build-pipeline REPO=<repo_name> REPO_BRANCH=<branch>` to delete the Pipline stack.
* Run `make delete-foundation ENV=<environment>` to delete the Foundation stack.
* Run `make delete-deps ENV=<environment>` to delete the required S3 buckets.

## Environment specifics

| Environment | CidrBlock |
| ------------- | ------------- |
| integration  | 10.1.0.0/16  |
| staging  | 10.2.0.0/16  |
| production  | 10.3.0.0/16  |

## Application specifics

| Application | ContainerPort | ListenerRulePriority |
| ------------- | ------------- | ------------- |
| bookit-api  | 8080  | 100  |
| bookit-client-react  | 4200 | 200  |

## Architectural Decisions

We are documenting our decisions [here](../master/docs/architecture/decisions)
