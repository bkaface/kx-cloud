/lb_gw
/Loadbalancing gateway for incoming
/Using Multi-threaded processing mode
/Using -30! for synchronous request processing

/Expected start: q lb_gw.q -p 5001  -dynamic 1

//Configurations: 
/assessFreq: 10000;					/frequency with which to assess the load on the gw
/avgQryExT:51;						/average Query execution time
/waitQryThreshT:100; 				/wait time we can accept on queries before we decide to start up a new process
/prcInc:1;							/process increment - increase client processes by this by spawning new processes
/dynamic:0b;						/specifies whether to enable the dynamic loadbalancing or just work with whatever connects
/bInsts:2;							/number of instances to keep running as the basic setup. Won't go below this.

\d .lb

/maxFlex:system["s"]; 				/the maximum number of slaves available for scaling
init:{availInst:: `$"," vs getenv `slave_IDs; 		/per envvar specified specific to Kx aws instances
	runningInst::();
	/spawnCmd:: "aws ec2 start-instances --instance-id ";		/start AWS instance
	/stopCmd:: "aws ec2 stop-instances --instance-ids ";			/stop AWS intance 
	track::()!();												/tracking queries with process thread
	instMap::()!();												/keeping map of the instances to conn. handles
	/processing command line parameters
	default: (!) . flip ((`bInsts;2);				/base instances to run
						(`assessFreq;50000);		/how often to assess throughput 
						(`waitQryThreshT;100);		/wait time threshold
						(`instInc;1);				/how many new instances to start when limit threatened
						(`dynamic;1);				/whether to run in dynamic spin up mode, or just in responsive 
						(`avgQryExT;51));			/average query execution time
	settings: default^ $[count .z.x;("J"$ .Q.opt .z.x)[;0];()!()];		/updating settings with cmd line args
	system"l ",getenv[`scripts_dir],"cmds.q";
	(`.[`getCmds])[`$getenv `platform;`.lb];					/get the appropriate commands for start stop instances
	currentInst::parseInst getInstCmd;				/get the currentinstance name
	@[`.lb;key[settings];:;value[settings]]; 		/set values in namespace from parameters
	/start dynamic loadbalancing if required
	.z.ts::?[`boolean$dynamic;						/check if dynamic
		[{assessLoad[];assessSlaves[];}];			/if dynamic, assess query load and balance as needed and update slaves based upon connections
		[{assessSlaves[];}]							/else just update slaves 
	];
	system"t ",string assessFreq;					/setting timer to assesment Frequency
 };

//starting and stopping processes 
/starting instances 
startMultInst:{[numInst] instances:getNxtInstances[numInst];	/Command to start a specified number of instances
			startInst each instances;
		};
		/,getenv[`scripts_dir],"logs/cmd.out &"
startInst:{[instName] x:spawnCmd,string[instName],">",getenv[`scripts_dir],"logs/cmd.out 2>&1 &";0N! x; 		/Command to start a specific instance
			system[x];
		};
getNxtInstances:{[numInst] numInst sublist availInst}			/Show us the next instance to start

/stopping instances 
stopMultInst:{[instHandles] instances:instMap?instHandles;		/get instance handles
			stopInst each instances;
		};
stopInst:{[instName] unregister[instMap[instName]];
			if[instName<>currentInst;							/only stopping if running on other instance to GW proc
				[x:stopCmd,string[instName]," 2>&",getenv[`scripts_dir],"logs/cmd.out &";0N! x; 				/running awscli command to stop
				system[x]]];
		};
//end code for starting and stopping slaves

//registering and unregistering remote processes
/called by registering instances 
register:{[instName] 0N! "Establishing connection from instance - ",string instName;
			availInst:: distinct availInst except instName;		/update list of available Instances
			runningInst:: distinct runningInst,instName;		/add to running instances
			instMap[instName]:.z.w;								/map instance to handle
			track::@[track;.z.w;:;()];							/update tracking dict
		};
/called on handle close
unregister:{[handle] instName:instMap?handle;					/get instance name from handle
			runningInst:: distinct runningInst except instName;	/remove from running instance list
			availInst,:instName;								/return to available instance list 
			track:: enlist[handle] _ track;						/remove from tracking dict
			instMap:: enlist[instMap?handle] _ instMap;			/update instance mapping
			@[hclose;handle; {[x;handle]0N! "Handle ",string[handle]," closed from remote server"}[;handle]];
		};
//end code for registering and unregistering remote processes

//loadbalancing code
getMostFreeHandle:{free?min free:(count')track};	/return handle with least queued queries
			
/called on remote slave processes
processQuery:{[clientHandle;query] 
				neg[.z.w] (`.lb.callback;clientHandle;@[(0b;)value@;query;{[err] (1b;err)}]);	/execute the query or capture error and callback
				neg[.z.w] (::) 									/return the executed query to Master, indicating if errored, flush
			};
/called on return from slave processes
callback:{[clientHandle;result]
			-30! clientHandle,result;						/send the received result back to the calling query Process
			track[.z.w]: track[.z.w] except clientHandle; 	/clearing this query from tracker
		};
//end code for loadbalancing

//Code for responsive slave scaling
assessLoad:{queue: (count') track;
			$[any waitQryThreshT < avgQryExT*queue; 		/are we in danger of not meeting threshold query return times?
				[0N!"Increasing available Instances";
				startMultInst[instInc]];					/spawn the new slaves as per the incremental increase specified 
			any c:0= bInsts _ queue;						/check if any slaves not being used, and more than the base Slaves running
				[0N!"Reducing available Instances";
				stopMultInst[where c]];
			count[track]< bInsts;							/if not running at base level
				[0N! "Increasing the base number of Instances as not at base level";
				startMultInst[bInsts - count track]];		/removing the slaveHandles that are unused and not 
			]
		};
assessSlaves:{system "s ",string neg count track;}			/updating slave threads based on process connections
//end code for responsive slave scaling

//set up .z handlers 
/specify how to retrieve slave handles
.z.pd:{`u#key track}								/if you are inclined to peach commands
/on closure of connection 
.z.pc:{if[x in key track;unregister[x]];}
/on incoming sync request - asynch is not in keeping with purpose of the gw
.z.pg:{slv:getMostFreeHandle[];					/getting the slave handle that will process this request 
		track[slv],:.z.w;						/tracking usage on the slaves
		-30!(::);								/sending the deffered response back to the querying process
		neg[slv] (processQuery;.z.w;x);			/sending the query to slave for execution
	};
//end .z handlers

/startMultInst[bInsts]
\d .

//for aws demo - loading mounts 
/system"l /hdb/db"

//can also do some funny things with the xinted stuff too ... tbc
//
