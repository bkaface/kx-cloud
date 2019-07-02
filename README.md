# kx-cloud

Example of Auto-Scaling code for Cloud installations using kdb+.

## Requirements

- kdb+ ≥ v3.6 64-bit (leveraging the kdb+ feature addition of [-30!](https://code.kx.com/v2/basics/internal/#-30x-deferred-response) or deferred response)
- Cloud provider AWS or GCP
- Instances which are utilized have the required CLI's installed
- Assumption that a hdb from dev/sdb is mounted on /hdb on the slave processes
- Assumption that the hdb once mounted is found under /hdb/db

## Setup
The run_slave.sh script is to be run at instance startup on the slave processes - this can be achieved by specifying this as a startup script within the cloud providers console. The required environmental variables can be called either through sourcing a configuration file (see run_gw.sh example with config/gw_config.cfg) or directly through this startup script (see run_slave.sh).

N.B. External disks can be mounted and shared between instances in Read only mode with GCP, and LustreFx can be mounted across slave instances in AWs. For more information on S3 Storage options in kdb+ see this [whitepaper] (https://code.kx.com/v2/cloud/aws/)


## Expected Usage 
Parameter expectation and explanation is found within the individual scripts. 
A simple running example can be obtained with a git clone of this project on all GW and Slave instances and running the below on the GW process (after configuring connections to hdb processes - see config.gw). 
    
    q /home/rebecca/q_scripts/lb_gw.q -p 2001 -s -4 -bInsts 1
    
This will start a gw process on port 2001 with 4 slaves (which is quickly changed to 1 slave on code initialisation) and specifies the basic amount of slave processes to keep running as 1 (this will be the first one specified in the gw_config.cfg file). 

N.B. The GW process has an initialisation command that needs to be uncommented in order to run upon instance startup.
Once the process is started to commence operation the following command should be called: 

    q).lb.init[]




## Additional comments and extensions 
In the same way that the start and stop instance commands are called here via the CLI's, whole instances can be created and deleted using similar commands and preconfigued instance images.

Additionall cloud based CPU metric auto-scaling groups can be used rather than custom kdb+ based monitoring code as seen in this example. 
