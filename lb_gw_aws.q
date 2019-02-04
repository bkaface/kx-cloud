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
init:{availInst:: `$("i-0bd707cc93f3ccd68";"i-06e47cd87b66c9ad5";"i-098b32ca1d1ecad40");
	runningInst::();
	spawnCmd:: "aws ec2 start-instances --instance-id ";
	stopCmd:: "aws ec2 stop-instances --instance-ids ";
	track::()!();						/tracking queries with process thread
	instMap::()!();
	/processing command line parameters
	default: (!) . flip ((`bInsts;2);				/base instances to run
						(`assessFreq;10000);		/how often to assess throughput 
						(`waitQryThreshT;100);		/wait time threshold
						(`instInc;1);				/how many new instances to start when limit threatened
						(`dynamic;1);				/whether to run in dynamic spin up mode, or just in responsive 
						(`avgQryExT;51));			/average query execution time
	settings: default^ $[count .z.x;("J"$ .Q.opt .z.x)[;0];()!()];		/updating settings with cmd line args
	@[`.lb;key[settings];:;value[settings]]; 	/set values in namespace from parameters
	//start dynamic loadbalancing if required
	?[`boolean$dynamic;
		[system"t ",string assessFreq;.z.ts: {assessLoad[];assessSlaves[];}];
		[system"t ",string assessFreq;.z.ts:assessSlaves]
	];
 };

//starting and stopping processes 
/start new processes 
startMultInst:{[numInst] instances:getNxtInstances[numInst];
			startInst each instances;
		};
startInst:{[instName] x:spawnCmd,string instName;0N! x; 
			system[x];
		};
getNxtInstances:{[numInst] numInst sublist availInst}
register:{[instName] .rk.x:instName;runningInst,:instName;
			availInst:: distinct availInst except instName;
			runningInst,:instName;
			instMap[instName]:.z.w;
			track::@[track;.z.w;:;()];				
		};
stopMultInst:{[numInst] /instances:neg[numInst] sublist bInsts _ runningInst;
			stopInst each instance;
		};
stopInst:{[instName] unregister[instMap[instName]];
			x:stopCmd,string instName;0N! x; 
			system[x];
		};
unregister:{[handle] instName:instMap?handle;
			runningInst:: distinct runningInst except instName;
			availInst,:instName;
			track:: enlist[handle] _ track;
			instMap:: enlist[instMap?handle] _ instMap;
			@[hclose;handle; {[x;handle]0N! "Handle ",string[handle]," closed from remote server"}[;handle]];
		};

//loadbalancing	 code:
getMostFreeHandle:{free?min free:(count')track};	/return handle with least queued queries
//end code for starting and stopping slaves
			
//Code for query distribution
/called on remote slave processes
processQuery:{[queryHandle;query] 
				neg[.z.w] (`.lb.callback;queryHandle;@[(0b;)value@;query;{[err] (1b;err)}]);
				neg[.z.w] (::) /return the executed query to Master, indicating if errored, flush
			};
/called on return from slave processes
callback:{[clientHandle;result]
			-30! clientHandle,result;						/send the received result back to the calling query Process
			track[.z.w]: track[.z.w] except clientHandle; 	/clearing this query from tracker
		};
//end code for query dist.

//Code for responsive slave scaling
assessLoad:{queue: (count') track;
			$[any waitQryThreshT < avgQryExT*queue; 		/are we in danger of not meeting threshold query return times?
				[0N!"Increasing available Instances";
				startMultInst[instInc]];						/spawn the new slaves as per the incremental increase specified 
			any c:0= bInsts _ queue;						/check if any slaves not being used, and more than the base Slaves running
				[0N!"Reducing available Instances";
				stopMultInst[where c]];
			count[track]< bInsts;
				[0N! "Increasing the base number of Instances as not at base level";
				startMultInst[bInsts - count track]];						/removing the slaveHandles that are unused and not 
			]
		};
assessSlaves:{system "s ",string neg count track;}

checkBase:{if[count[track]< bInsts;startMultInst[bInsts - count[track]]]};
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

//can do some funny things with the xinted stuff for this...
//
