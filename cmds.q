`AWS`GCP!((!/) flip ((`spawnCmd;"aws ec2 start-instances --instance-id ");
					(`stopCmd;"aws ec2 stop-instances --instance-ids ");
					(`currentInst;"ec2metadata --instance-id"));
		(!/) flip 	((`spawnCmd;"gcloud compute instances start ");
					(`stopCmd;"gcloud compute instances start ")
					(`instanceName;"curl http://metadata.google.internal/computeMetadata/v1/instance/hostname -H Metadata-Flavor:Google")));