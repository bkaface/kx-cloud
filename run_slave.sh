#!/bin/bash
echo "Running at `date`" >> /tmp/RES

#Setting up the q environment
export QHOME=/opt/kx/q          #etc
alias q='rlwrap $QHOME/l64/q'

#Configuration for environment - rather than souring slave_config.cfg file 
export platform=GCP         
export scripts_dir=/home/rebecca/q_scripts/
export masterPort=2001              #update for your own settings
export masterHost=10.142.0.2        #update for your own settings

#Mounting the hdb 
sudo mount /dev/sdb /hdb            #update for your own settings

#Running the q-script
nohup $QHOME/l64/q /home/rebecca/q_scripts/lb_slave_aws.q -s 2 -masterPort $masterPort -masterHost $masterHost &>/tmp/QLOGS &

echo "Script completed at `date`"