# 3. Use AWS CodePipeline and CodeBuild instead of Travis

Date: 2017-09-27

## Status

Accepted

Amends [2. Use AWS Bare Metal Rig approach](0002-use-aws-bare-metal-rig-approach.md)

## Context

Travis has some limitations about what stages you can use to create a pipleine.  We still desire to have a hosted/PaaS CI/CD solution

## Decision

* Use AWS CodePipeline and CodeBuild instead of Travis

## Consequences

* We don't know enough about CodeBuild/CodePipeline to understand whether it's the right fit or not.
* We've already found that CodePipeline is tied to a branch potentially making it hard to run pipelines for branches and PRs
