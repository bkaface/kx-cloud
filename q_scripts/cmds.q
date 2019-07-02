//Command line code is specific for each cloud providers - different CLI's 
//These CLI commands are used on both the slaves and the GW's so this function is used by both
getCmds:{[platform;context]
    /create dictionary mapping the platform commands to the CLI's for each
	cmdDict:`AWS`GCP!((!/) flip ((`spawnCmd;"aws ec2 start-instances --instance-id ");	/start AWS instance, needto specifiy 
					(`stopCmd;"aws ec2 stop-instances --instance-ids ");				/stop AWS instance 
					(`getInstCmd;"ec2metadata --instance-id");                          /get current server Instance Name 
					(`parseInst;{`$raze system x}));						/additional function to parse full Instance Name command
		
        (!/) flip 	((`spawnCmd;"nohup gcloud compute instances start --zone $zone ");	/start GCP Instance
					(`stopCmd;"nohup gcloud compute instances stop --zone $zone ");		/stop GCP Instance
					(`getInstCmd;"curl http://metadata.google.internal/computeMetadata/v1/instance/hostname 
                                    -H Metadata-Flavor:Google");                        /get current server Instance Name 
					(`parseInst;{`$first "." vs first system x})));         /additional function to parse full Instance Name command
	/get the correct commands for the specified platform
    cmds:cmdDict[platform];         
    /set those commands in the correct context
	@[context;key[cmds];:;value[cmds]]};