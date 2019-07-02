#!/bin/bash
instances="${1:-1}"

# source env variables
source /home/rebecca/config/gw_config.cfg
echo $slave_IDs
# kick off the kdb script needed for connection to the master process 
nohup q /home/rebecca/q_scripts/lb_gw_aws.q -p 2001 -s -4 -bInsts $instances &>/dev/null &
#q /home/ubuntu/rebecca/AWS_meetup/lb_slave_aws.q -masterPort 2001 -masterHost 172.31.49.67 -s 2

