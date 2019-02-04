/lb_slave_aws.q 
//Assumes an existing and running master process
//Called with syntax as follows:
//q lb_slave.q -masterPort 2330 -masterHost 

\d .lb
instanceName: system "ec2metadata --instance-id"; 							/whatever command I need to run to get the instance name on the env
shutDownCmd: "aws ec2 stop-instances --instance-ids ",instanceName;			/whatever aws command will shut down this instance from within
d: .Q.opt .z.x;
instanceName: instanceName^`$raze d[`instanceName];
/errorDict: ((),1)!enlist("Conn Refused:Slave Connections exceeding configured slave settings on Master")

if[not `masterPort in key d;
	 0N! "MasterPort parameter not passed - exiting";
	 system"\\"];
if[not `masterHost in key d;
	 0N! "MasterHost parameter not passed - exiting";
	 system"\\"];

/when connection closed
.z.pc:{[h]0N! shutDownCmd; 
		system[shutDownCmd]
		};

/on the servers 
h: hopen hsym `$":" sv raze d[`masterHost`masterPort];

//register with the remote process
neg[h] (`.lb.register;`$instanceName)

//potentially add some stuff here on refused connection etc.


\d . ;
2+2