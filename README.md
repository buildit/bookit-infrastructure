# AWS The Rig

This setup will create a CloudFormation, GoCD powered Rig on AWS.

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
ENV = <Environment i.e.: tst, dev, stg, prd>
KEY_NAME = <EC2 SSH key name>
OWNER = <The owner of the stack, either personal or corporate>
PROFILE = <AWS Profile Name>
PROJECT = <Project Name>
REGION = <AWS Region>
```

Or also done interactively through `make .make`.

Run `make deps` to create required S3 buckets.

Confirm everything is valid with `make check-env`

## Makefile Targets

  * Run `make create-foundation` to start an AWS Bare Rig Foundation Stack.

This is the Stack that will be shared by all management and services in an AWS Region.

  * Run `make status-foundation` to check status of the stack. (Should be `CREATE_COMPLETE`)
  * Check the outputs as well with `make outputs-foundation`
  * Run `make create-app`, same options for status: `make status-app` and outputs `make outputs-app`


To delete everything, in order:

  * Run `make delete-app` to delete the App stack.
  * Run `make delete-foundation` to delete the Foundation stack.
