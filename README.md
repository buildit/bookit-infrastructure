# AWS The Rig

This setup will create a CloudFormation, AWS CodePipeline/CodeBuild/CodeDeploy powered Rig on AWS.

## Setup

### Dependencies

For using this repo you'll need:

* AWS CLI, and credentials working: `brew install awscli && aws configure`
* Setup `.make` for local settings

This can either be done by copying settings from the template `.make.example`
and save in a new file `.make`:

```ini
DOMAIN = <Domain to use for Foundation>
KEY_NAME = <EC2 SSH key name>
OWNER = <The owner of the stack, either personal or corporate>
PROFILE = <AWS Profile Name>
PROJECT = <Project Name>
REGION = <AWS Region>
```

Or also done interactively through `make .make`.

For the "real" bookit riglet:

```ini
DOMAIN = buildit.tools
KEY_NAME = buildit-bookit-ssh-keypair
OWNER = buildit
PROFILE = default
PROJECT = bookit
REGION = us-east-1
PREFIX =
```

Confirm everything is valid with `make check-env`

## Feeling Lucky?

* `./create-standard-riglet.sh` to create a full riglet with standard environments.
* `./delete-standard-riglet.sh` to delete it all.

## Makefile Targets

The full build pipeline requires at least integration, staging, and production environments, so the typical
installation is:

* Run `make create-deps`
* Run `make create-environment ENV=integration`
* Run `make create-environment ENV=staging`
* Run `make create-environment ENV=production`
* Check the outputs of the above with `make outputs-environment ENV=<environment>`
* Check the status of the above with `make status-environment ENV=<environment>`
* Run `make create-build REPO=<repo_name> CONTAINER_PORT=<port> LISTENER_RULE_PRIORITY=<priority>`, same options for status: `make status-build` and outputs `make outputs-build`
  * REPO is the repo that hangs off buildit organization (e.g "bookit-api")
  * CONTAINER_PORT is the port that the application exposes (e.g. 8080)
  * LISTENER_RULE_PRIORITY is the priority of the the rule that gets created in the ALB.  While these won't ever conflict, ALB requires a unique number across all apps that share the ALB.  See [Application specifics](#application-specifics)


To delete everything, in order:

* Run `make delete-app ENV=<environment> REPO=<repo_name> REPO_BRANCH=<branch>` to delete the App stacks.
  * if you deleted the pipeline first, you'll find you can't delete the app stacks because the role that created them is gone.  You'll have to manually delete via aws cli and the `--role-arn` override
* Run `make delete-build REPO=<repo_name>` to delete the Pipline stack.
* Run `make delete-environment ENV=<environment>` to delete the Compute stack.
* Run `make delete-foundation-deps ENV=<environment>` to delete the required S3 buckets.
* Run `make delete-deps` to delete the required SSM parameter.

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

## Logs

We are using CloudWatch for centralized logging.  You can find the logs for each environment and application at [here](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logs:prefix=buildit)

## Architectural Decisions

We are documenting our decisions [here](../master/docs/architecture/decisions)
