getCmds:{[platform;context]
	cmdDict:`AWS`GCP!((!/) flip ((`spawnCmd;"aws ec2 start-instances --instance-id ");	/start AWS instance
					(`stopCmd;"aws ec2 stop-instances --instance-ids ");				/stop AWS instance 
					(`getInstCmd;"ec2metadata --instance-id");
					(`parseInst;{`$raze system x}));						/get Instance Name
		(!/) flip 	((`spawnCmd;"nohup gcloud compute instances start --zone $zone ");						/start GCP Instance
					(`stopCmd;"nohup gcloud compute instances stop --zone $zone ");						/stop GCP Instance
					(`getInstCmd;"curl http://metadata.google.internal/computeMetadata/v1/instance/hostname -H Metadata-Flavor:Google");
					(`parseInst;{`$first "." vs first system x})));
	cmds:cmdDict[platform];
	@[context;key[cmds];:;value[cmds]]};