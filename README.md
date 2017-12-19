# AWS The Rig

This setup will create a CloudFormation, AWS CodePipeline/CodeBuild/CodeDeploy powered Rig on AWS.

## Setup

### Dependencies

For using this repo you'll need:

* AWS CLI (v1.11.57 minimum), and credentials working: `brew install awscli && aws configure`
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
DOMAIN_CERT = <AWS Certificate Manager GUID>
EMAIL_ADDRESS = <optional> email address for potential notifications.
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
DOMAIN_CERT = 0663e927-e990-4157-aef9-7dea87faa6ec
PREFIX =
EMAIL_ADDRESS = u9o1x0a2t4y0g0k1@wiprodigital.slack.com
```

Confirm everything is valid with `make check-env`

### Firing it up

#### Feeling Lucky? Uber-scripts!

There are a couple of scripts that automate the detailed steps covered further down.  They hide the
details, which is both a good and bad thing.

* `./create-standard-riglet.sh` to create a full riglet with standard environments (integration/staging/production).
* `./delete-standard-riglet.sh` to delete it all.


#### Individual Makefile Targets

If you're not feeling particularly lucky, or you want to understand how things are assembled, or create a custom environment, or what-have-you, follow this guide.

##### Building it up

The full build pipeline requires at least integration, staging, and production environments, so the typical
installation is:

###### Execution/runtime Infrastructure and Environments

* Run `make create-deps`
* Run `make create-environment ENV=integration` (runs `create-foundation`, `create-compute`, `create-db`)
* Run `make create-environment ENV=staging`
* Run `make create-environment ENV=production`

###### Build "Environments"

In this case there's no real "build environment", unless you want to consider AWS services an environment.
We are using CodePipeline and CodeBuild, which are build _managed services_ run by Amazon (think Jenkins in 
the cloud, sort-of).  So what we're doing in this step is creating the build pipeline(s) for our code repo(s).

* Run `make create-build REPO=<repo_name> CONTAINER_PORT=<port> LISTENER_RULE_PRIORITY=<priority>`, same options for status: `make status-build` and outputs `make outputs-build`
  * REPO is the repo that hangs off buildit organization (e.g "bookit-api")
  * CONTAINER_PORT is the port that the application exposes (e.g. 8080)
  * LISTENER_RULE_PRIORITY is the priority of the the rule that gets created in the ALB.  While these won't ever conflict, ALB requires a unique number across all apps that share the ALB.  See [Application specifics](#application-specifics)
  * (optional) REPO_BRANCH is the branch name for the repo - MUST NOT CONTAIN SLASHES!
  * (optional) PREFIX is what goes in front of the URI of the application.  Defaults to OWNER but for the "real" riglet should be set to blank (e.g. `PREFIX=`)
  * (optional) SLACK_WEBHOOK is a slack URL to which build notifications are sent.  
    > If not included, no notifications are sent.  Be aware of this when issuing `make create-update` commands on existing stacks! 

###### Deployed Applications

It gets a little weird here.  You never start an application yourself in this riglet.  The build environments
actually dynamically create "app" stacks in CloudFormation as part of a successful build.  These app stacks
represent deployed and running code (they basically map to ECS Services and TaskDefinitions).

##### Tearing it down

To delete a running riglet, in order:

* Run `make delete-app ENV=<environment> REPO=<repo_name>` to delete any running App stacks.
  * if for some reason you deleted the pipeline first, you'll find you can't delete the app stacks because
    the role under which they were created was deleted with the pipeline. In this case you'll have to create
    a temporary "god role" and manually delete the app via the `aws cloudformation delete-stack` command,
    supplying the `--role-arn` override.
* Run `make delete-build REPO=<repo_name> REPO_BRANCH=<branch>` to delete the Pipline stack.
* Run `make delete-environment ENV=<environment>` to delete the Environment stack (runs `delete-db`, `delete-compute`, `delete-foundation`)
* Run `make delete-deps` to delete the required SSM parameters.

### Checking on things

* Check the outputs of the activities above with `make outputs-foundation ENV=<environment>`
* Check the status of the activities above with `make status-foundation ENV=<environment>`
* Check AWS CloudWatch Logs for application logs.  In the Log Group Filter box search
  for for `<owner>-<application>` (at a minimum).  You can then drill down on the appropriate
  log group and individual log streams.

## Environment specifics

For simplicity's sake, the templates don't currently allow a lot of flexibility in network CIDR ranges.
The assumption at this point is that these VPCs are self-contained and "sealed off" and thus don't need
to communicate with each other, thus no peering is needed and CIDR overlaps are fine.

Obviously, the templates can be updated if necessary.

| Environment    | CidrBlock      | Public Subnets (Multi AZ) | Private Subnets (Multi AZ)
| :------------- | :------------- | :-------------            | :-------------
| integration    | 10.1.0.0/16    | 10.1.1.0/24,10.1.2.0/24   | 10.1.11.0/24,10.1.12.0/24
| staging        | 10.2.0.0/16    | 10.2.1.0/24,10.2.2.0/24   | 10.2.11.0/24,10.2.12.0/24
| production     | 10.3.0.0/16    | 10.3.1.0/24,10.3.2.0/24   | 10.3.11.0/24,10.3.12.0/24

## Database specifics

We're currently using AWS RDS Aurora MySQL 5.6.x

| Environment    | DB URI (internal to VPC)              | DB Subnets (Private, MultiAZ) 
| :------------- | :-------------                        | :-------------  
| integration    | mysql://aurora.bookit.internal/bookit | 10.1.100.0/24,10.1.110.0/24 
| staging        | mysql://aurora.bookit.internal/bookit | 10.2.100.0/24,10.2.110.0/24 
| production     | mysql://aurora.bookit.internal/bookit | 10.3.100.0/24,10.3.110.0/24 

## Application specifics

| Application         | ContainerPort  | ListenerRulePriority
| :-------------      | :------------- | :------------- 
| bookit-api          | 8080           | 100  
| bookit-client-react | 4200           | 200  

## Scaling

There are a few scaling "knobs" that can be twisted in running stacks, using CloudFormation console.
Conservative defaults are established in the templates, but the values can (and should) be updated
in specific running riglets later.

For example, production ECS should probably be scaled up, at least horizontally, if only for high availability,
so increasing the number of cluster instances to at least 2 (and arguably 4) is probably a good idea, as well
as running a number of ECS Tasks for each bookit-api and bookit-client-react.  ECS automatically distributes the Tasks
to the ECS cluster instances.

The same goes for the RDS Aurora instance.  We automatically create a replica for production (horizontal scaling).
To scale vertically, give it a larger box.  Note that a resize of the instance type should not result in any lost data.

The above changes can be made in the CloudFormation console.  To make changes find the appropriate stack,
select it, choose "update", and specify "use current template".  On the resulting parameters page make appropriate
changes and submit.

It's a good idea to always pause on the final submission page to see the predicted actions for your changes
before proceeding, or consider using a Change Set.

### Application Scaling Parameters

| Parameter                    | Scaling Style | Stack                      | Parameter
| :---                         | :---          | :---                       | :---
| # of ECS cluster instances   | Horizontal    | compute-ecs                | ClusterSize/ClusterMaxSize |
| Size of ECS Hosts            | Vertical      | compute-ecs                | InstanceType    |
| Number of Tasks              | Horizontal    | app (once created by build)| TaskDesiredCount |

### Database Scaling Parameters

And here are the available *database* scaling parameters.

| Parameter             | Scaling Style | Stack         | Parameter
| :---                  | :---          | :---          | :---
| Size of RDS Instances | Vertical      | db-aurora     | InstanceType 
| # of RDS Instances    | Vertical      | db-aurora     | _currently via Replication property in Mappings inside db-aurora/main.yaml_ 

## Maintenance

Except in very unlikely and unusual circumstances _all infrastructure/build changes should be made via CloudFormation
updates_ either by submitting template file changes via the appropriate make command, or by changing parameters in
the existing CloudFormation stacks using the console.  Failure to do so will cause the running environment(s) to diverge
from the as-declared CloudFormation resources and may (will) make it impossible to do updates in
the future via CloudFormation.

> An alternative to immediate execution of stack updates in the CloudFormation console is to use the "change set"
> feature. This creates a pending update to the CloudFormation stack that can be executed immediately, or go through an
> approval process.  This is a safe way to preview the "blast radius" of planned changes, too before committing.

### Updating ECS AMIs

If your riglet instance is using the "ec2" compute type, the ECS cluster runs Amazon-supplied AMIs.  The AMIs are 
captured in a map in the `compute-ecs/ec2.yaml` template.  Occasionally, Amazon releases newer AMIs and marks 
existing instances as out-of-date in the ECS console.  To update to the latest set of AMIs, run the 
`./cloudformation/scripts/ecs-optimized-ami.sh` script and copy the results into the `compute-ecs/ec2.yaml` 
template's `AWSRegionToAMI` mapping.

## Logs

We are using CloudWatch for centralized logging.  You can find the logs for each environment and application at [here](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logs:prefix=buildit)

Alarms are generated when ERROR level logs occur.  They currently get sent to the #book-it-notifications channel

## Architectural Decisions

We are documenting our decisions [here](../master/docs/architecture/decisions)
