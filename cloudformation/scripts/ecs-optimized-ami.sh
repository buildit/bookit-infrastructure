#!/bin/bash

# Code generator to create map of AMIs by region.  See AWSRegionToAMI mapping in ecs-cluster.yaml.
curl -s "http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html" | \
  gawk '/<td><code ([^>]*)>([^<]*)<\/code>/{ match($NF, /([a-z]{2,3}?\-[a-z0-9\-]+)/, arr); print arr[0]; }' | \
  gawk '{key=$0; getline; print "    " key ":\n      AMI: " $0;}'
