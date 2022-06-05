//****************************** Promela Model of the Contiki's scheduler
//**************************************************************** Parameters to be set
//Using SPIN 6.5.0  and iSpin 1.1.1
//Storage Mode : bitstate/supertrace
//Search Mode  : depth-first search +Partial order reduction
//***************************** Advanced Parameters
// Physical Memory Available (in Mbytes) : 1024
// Estimated State Space Size (states * 10 ^ 3) : 1000
// Maximum Search Depth (steps) : 50000
// Nr of hash-functions in Bitstate mode: 3
// Size for Minimized Automaton : 100
// Extra Compile-Time Directives : -O2   -DVECTORSZ=2048 

//****************************************************************End of parameters to be set
//*************************************************************** Model descrption
// Data structures and global variables: 41-84
// Environment Model: 
//	   Boot-up : 166-171 (Invoke Processes_initialization to initialize environment, then transfer control to the main function)
//     Processes_initialization: 142-162 (Create atmost max_nProcesses number of Contiki processes and add them into autostart_processes randomly)
//		main()    : 172-187 (Start autostart processes, then transfer control to the scheduler)
// 		autostart_start() : 361-378(Start autostart processes)
//		ISR : 670-686
//		other Contiki's macro or functions:
//				PT_INIT() : 100-108
//				process_post_synch() : 231-243
//				process_post(): 244-257
//				process_start() : 294-321
//				process_poll() : 338-357
// Contiki's scheduler functions:
//		process_run() : 592-609
//		do_poll() : 513-538
//		call_process() : 470-511
//		do_event() : 539-591
//		exit_process() : 389-468
//      process_is_running() : 380-388
//		process thread : 610-668
//	LTL formula: 690-827
//  repair1 : 578-582
//  repair2 : 500-508
//  repair3 : 418
//*************************************************************End of model descrption


#define max_nProcesses 5
#define PROCESS_CONF_NUMEVENTS  32 
#define PROCESS_BROADCAST 1000
#define max_nAutoStartProcesses 30
#define PROCESS_ERR_FULL 1000
#define NULL 1000

mtype: process_event_t = {PROCESS_EVENT_NONE , PROCESS_EVENT_INIT, PROCESS_EVENT_POLL, PROCESS_EVENT_EXIT, 
PROCESS_EVENT_SERVICE_REMOVED, PROCES_EVENT_CONTINUE, PROCESS_EVENT_MSG, PROCESS_EVENT_EXITED,
PROCESS_EVENT_TIMER, PROCESS_EVENT_COM, PROCESS_EVENT_MAX,ASIGN_PTHREAD,THREAD_INIT}

mtype: proc_state= {PROCESS_STATE_NONE,PROCESS_STATE_CALLED,PROCESS_STATE_RUNNING}

mtype: ptResult = { PT_WAITING, PT_YIELDED, PT_EXITED, PT_ENDED,PT_CREATED }
int poll_requested ;//--- process.c:75
int nevents;//--- process.c:68
int fevent;//--- process.c:68

//--- process.h:315-326
int nProcesses;
typedef process {
	int next;
	byte name[9];
	int thread;
	byte needspoll;
	mtype: proc_state state;
}
process processes[max_nProcesses];
int processes_valid[max_nProcesses]; //Verificaton
//--- End of process.h:315-326
int autostart_processes[max_nAutoStartProcesses];

int nAutoStartProcesses ;

int process_list = NULL;// process.c:54
int process_current = NULL;// process.c:55
mtype:process_data_t ={nill,killed_p};
//--- process.c:62-66
typedef event_data {
 	mtype: process_event_t ev;
	mtype: process_data_t   data;       
	int p;
}
event_data events[PROCESS_CONF_NUMEVENTS];
//--- End of process.c:62-66
//****************************************** Channels
chan pThread_params_chan = [1] of {short,int , int };
chan pThread_sync_chan = [0] of {int,mtype:ptResult};
chan poll_sync_chan = [0] of {int};
chan ret_chan_thread = [0] of {mtype: ptResult};


//*****************************************Variabels for verificaton
int calledProcess_id= NULL;
int isTerm[max_nProcesses];
int  sent_ev;
//*****************************************End of Variabels for verificaton

//***************************************** Environment Model
proctype  PT_INIT(int p;chan syn_chan) //pt.h\PT_INIT:79
{
    if 
	::(processes[p].thread==NULL) -> skip
	:: else -> pThread_params_chan ! processes[p].thread,THREAD_INIT , 0  
	fi		
	isTerm[p] = 0;
	syn_chan ! 0
} 

int r10;		// For random number
int r11;		// For random number
//**************** Create a Contiki process and assign a thread to it
proctype  _Process(int p;chan syn_chan)    // ---process.h\ PROCESS:301-311
{

	mtype:ptResult res1; 
	int r;
	processes[p].name[0]  = 'P';  
	processes[p].name[1] = 'R';  
	processes[p].name[2] = 'O';  
	processes[p].name[3] = 'C'; 
	processes[p].name[4] = 'E';  
	processes[p].name[5] = 'S'; 
	processes[p].name[6] = 'S';  
	processes[p].name[7] = '_';  
	processes[p].name[8] = p;
	processes[p].state = PROCESS_STATE_NONE; 
	processes[p].needspoll = 0;
	
    if
	:: r11 != 0 -> processes[p].thread = NULL; r11=0;
	:: r11 != 1 -> pThread_params_chan ! NULL,ASIGN_PTHREAD , 0 ; 
							 run pThread(); 
							 pThread_sync_chan  ? processes[p].thread,res1; r11=1;
	fi;
	processes_valid[p] = 0; 
	
	end: syn_chan ! 0;
}// ---End of process.h\ PROCESS:301-311
//**************** Create atmost max_nProcesses number of Contiki processes
//**************** and add them into autostart_processes randomly
proctype Processes_initialization(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int p;
	  do
	   ::   (p < max_nProcesses) ->
				run _Process(p,ret_chan); 
				ret_chan ? 0;
				if 
				::  (nAutoStartProcesses < max_nAutoStartProcesses)  ->  
							autostart_processes[nAutoStartProcesses] = p;  
							nAutoStartProcesses = nAutoStartProcesses+1
				::  else
				fi
				p++

	 :: (1)-> nProcesses = p; 
					break
	 od
  syn_chan ! 0
}
			
//*****************************************
//***************************************** Boot-up
init {
    chan ret_chan = [0] of {int};
    run Processes_initialization(ret_chan);
	ret_chan ? 0;
	run main()
}
proctype main()
{
     chan ret_chan =[0] of {int}; 
	 int temp,np;
	 np = _nr_pr;
	 run autostart_start(ret_chan);// Start autostart processes before transferring control to the scheduler
	 ret_chan ? 0;
	 np ==_nr_pr;
      do
	  :: (1) ->
		 np = _nr_pr;
		 run process_run(ret_chan);//Transfer control to the scheduler
	     ret_chan ? 0;
		 np==_nr_pr
	  od
}
// Choose a random event
proctype randomEvent(chan syn_chan)  
{
	int ev;
	if 
	:: (1) -> ev=PROCESS_EVENT_INIT;
	:: (1) -> ev=PROCESS_EVENT_EXIT;
	:: (1) -> ev=PROCESS_EVENT_NONE;
	:: (1) -> ev=PROCESS_EVENT_POLL;
	:: (1) -> ev=PROCESS_EVENT_SERVICE_REMOVED;
	:: (1) -> ev=PROCES_EVENT_CONTINUE;
	:: (1) -> ev=PROCESS_EVENT_MSG;
	:: (1) -> ev=PROCESS_EVENT_EXITED;
	:: (1) -> ev=PROCESS_EVENT_TIMER;
	:: (1) -> ev=PROCESS_EVENT_COM;
	:: (1) -> ev=PROCESS_EVENT_MAX;
	 fi;
	 end: syn_chan ! ev;
}		
int rp;
proctype randomProcess(int pocT;int fromp;chan syn_chan)// Choose a random process
{
	
	if
	:: (pocT==3) -> // Consider PROCESS_BROADCAST
		rp = (rp==PROCESS_BROADCAST -> 0:rp);
		do
		:: (rp >= 0 && rp < nProcesses - 1) -> rp++;
		:: (rp > 0 && rp <= nProcesses - 1) -> rp--;
		:: (1) -> rp = PROCESS_BROADCAST; break;
		::  break;
		od
	:: else -> 
		rp = (rp==PROCESS_BROADCAST -> 0:rp);
		do
		:: (rp >= 0 && rp < nProcesses - 1) -> rp++;
		:: (rp > 0 && rp <= nProcesses - 1) -> rp--;
		::  break;
		od
	fi;
	syn_chan ! rp;
}
 // ---process.c\process_post_synch:361-368
proctype process_post_synch(int p;int ev;chan syn_chan)
  {
	chan ret_chan = [0] of {int};
  	 int caller;
	 int NP;
	 NP=_nr_pr;
	 caller = process_current;
	run call_process(p,ev,nill,ret_chan); 
	ret_chan ? 0;
	(_nr_pr == NP);
	process_current = caller;
	syn_chan ! 0;
  }// ---End of process.c\process_post_synch:361-368
  proctype process_post(int p;int ev;chan syn_chan)// ---process.c\process_post:321-359
 {
	int snum;
	if  //process.c\process_post:335-344
	:: (nevents==PROCESS_CONF_NUMEVENTS) ->
		skip;//End of process.c\process_post:335-344
	:: else ->  
	      snum = (fevent + nevents) % PROCESS_CONF_NUMEVENTS;
         events[snum].ev = ev;
         events[snum].p = p;
          nevents++;
	fi;
	syn_chan ! 0;
}// ---End of process.c\process_post:321-359
proctype postRandomEvent(chan syn_chan) // Post a random event to a process randomly
{
	chan ret_chan = [0] of {int};
	int r_p = 0;
	int np_new4;
	int ev;
	np_new4 = _nr_pr; 
	run randomEvent(ret_chan); 
	ret_chan ? ev;
	(np_new4 == _nr_pr); 

	select( r_p : 0 .. nProcesses);
	r_p = (r_p==nProcesses->1000:r_p);
	postType: if 
	:: r_p==PROCESS_BROADCAST ->
			 np_new4 = _nr_pr; 
					run process_post(r_p,ev,ret_chan); // Post an asyncronous event
					ret_chan ? 0;
						(np_new4 == _nr_pr);
		 
	:: else ->
			if 
			:: (1) -> 
						np_new4 = _nr_pr; 
						run process_post(r_p,ev,ret_chan);
						ret_chan ? 0;
						(np_new4 == _nr_pr);
			:: (1) -> 
						 np_new4 = _nr_pr;
						 run process_post_synch(r_p,ev,ret_chan); // Post a sync event
						 ret_chan ? 0;
						 (np_new4 == _nr_pr);
			fi 
	fi;
	end: syn_chan ! 0;
}
proctype process_start(int p; chan syn_chan) //--- process.c\process_start:98-121
{
	chan ret_chan = [0] of {int};
	int np_new5;
	int q;
	q = process_list;
	do
	 :: (q==p || q==NULL ) -> break;
	 :: else -> q = processes[q].next;
	od;
	if
	::  q==p ->skip;
	:: else -> 
		processes[p].next = process_list; 
		processes_valid[p]=1; 
		process_list=p;
		processes[p].state= PROCESS_STATE_RUNNING;
		 np_new5 = _nr_pr;
		run PT_INIT(p,ret_chan); 
		ret_chan ? 0;
		 (np_new5 == _nr_pr);
		 np_new5 = _nr_pr;//process.c\process_start:120
		run process_post_synch(p,PROCESS_EVENT_INIT,ret_chan);
		ret_chan ? 0;
		 (np_new5 == _nr_pr);//process.c\process_start:120
	fi;
	syn_chan ! 0;
  }//--- End of process.c\process_start:98-121						  
proctype startRandomProcess(chan syn_chan)
{
	chan ret_chan_1 = [0] of {int};
	chan ret_chan_2 = [0] of {int};
	int r_p;
	int np_new3;

	select (r_p : 1 .. nProcesses);
	np_new3 = _nr_pr;						
	run process_start(r_p-1,ret_chan_2);	
	ret_chan_2 ? 0;	
	(np_new3 == _nr_pr);	

	end: syn_chan ! 0;		
}
// ---process.c\process_poll:370-380
 proctype process_poll()
 {
	int p;
	begin:  atomic{
	poll_sync_chan ? p;
    if 
    ::(p==NULL) -> 
		skip;
	:: else -> 
		 if   //process.c\process_poll:374-378
         ::((processes[p].state==PROCESS_STATE_RUNNING)||(processes[p].state==PROCESS_STATE_CALLED)) -> 
					 processes[p].needspoll = 1;
					//assert(processes_valid[p] == 1);
	                poll_requested = 1;
		:: else -> skip;
         fi; //End of process.c\process_poll:374-378
   fi

   poll_sync_chan ! NULL;
  }
   goto begin;
 } // ---End of process.c\process_poll:370-380
 // ---autoStart.c\autostart_start:51-60
proctype autostart_start(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int p;
	int np_new2;
	int i;
	do // autoStart.c\autostart_start:56-59
	:: (p < nAutoStartProcesses) -> 
					np_new2=_nr_pr;// autoStart.c\autostart_start:57
					i = autostart_processes[p];
				    run process_start(i,ret_chan);
					ret_chan ? 0;
					(np_new2 == _nr_pr);// autoStart.c\autostart_start:57
					p++;
	::	else -> break;
	od// End of autoStart.c\autostart_start:56-59
	syn_chan ! 0;
  }	// ---End of autoStart.c\autostart_start:51-60				
//--- process.c\process_is_running:382-386
proctype process_is_running(int p;chan syn_chan)
{
	int result;
	if 
	:: (processes[p].state==PROCESS_STATE_RUNNING) || (processes[p].state==PROCESS_STATE_CALLED) -> result =1;
	:: else -> result = 0;
	fi;
	syn_chan ! result;
}//--- End of process.c\process_is_running:382-386
proctype exit_process(int p; int fromProcess; chan sync_ch)//--- process.c\exit_process:123-172
{  
	chan ret_chan = [0] of {int};
	int preNP12; 
	mtype: ptResult ptRes; 
	int data;  
	int q; 
	int result;
	int old_current;
	begin: old_current = process_current;
	q = process_list; //- Begin of process.c\exit_process:133
	do 
	:: (q==NULL) || (q==p) -> break;
	::else -> q = processes[q].next;
   od;//- End of process.c\exit_process:133
	if //process.c\exit_process:134-136
	:: (q==NULL ) -> goto end;
	:: else -> skip;
	fi;//End of process.c\exit_process:134-136
	preNP12=_nr_pr;
	run process_is_running(p,ret_chan);
	ret_chan ? result;
	(_nr_pr == preNP12);
    if
	:: ( result) ->   
	      processes[p].state = PROCESS_STATE_NONE;   
		  processes[p].needspoll = 0; //repair3
		q = process_list;//process.c\exit_process:147-151
		do
		::  (q==NULL)   -> 
				break;
		::  else -> 
				if
				:: (q==p) ->
					skip;
				:: else -> 
					preNP12 = _nr_pr;
					run call_process( q,PROCESS_EVENT_EXITED,nill,ret_chan );  
					ret_chan ? 0;
					(_nr_pr == preNP12);
				fi; 
				q = processes[q].next;
		od;//End of process.c\exit_process:147-151
		if //process.c\exit_process:153-157
		::p==fromProcess ->  
				skip;
		:: else -> 
				process_current = p;
				pThread_params_chan ! processes[p].thread,PROCESS_EVENT_EXIT, data;
				pThread_sync_chan ? eval(processes[p].thread),ptRes;
		fi;
	:: else -> skip;
	fi;//End of process.c\exit_process:153-157
	if //process.c\exit_process:160-169
	::p==process_list ->  
		
	     process_list=processes[process_list].next; 
	     processes_valid[p] = 0; 
		 isTerm[p] = 0;
		
	:: else ->  q = process_list; //process.c\exit_process:163-168
			do
			:: q==NULL -> 
					break;
			::  else -> //process.c\exit_process:164-167
					if 
				::processes[q].next==p -> 
								
									processes[q].next = processes[p].next; 
									processes_valid[p] = 0; 
									
									break;//process.c\exit_process:164-167
				:: else -> skip;
				fi ;
				q = processes[q].next;
			od //End of process.c\exit_process:163-168
	fi; //End of process.c\exit_process:160-169
	end: process_current = old_current ;
	 sync_ch ! 0;
}//--- End of process.c\exit_process:123-172
//-Begin of process.c\call_process:174-199
proctype  call_process(int p;int  ev; int data; chan sync_ch)   
{ 
	chan ret_chan_exit = [0] of {int};

	int preNP;
	calledProcess_id = p;  
	sent_ev = ev;  
	int tmp;
	mtype:ptResult ptRes; 
	if //-- Begin of process.c\call_process:185-198
	:: (processes[p].state == PROCESS_STATE_RUNNING && processes[p].thread != NULL) ->
		process_current = p;
		processes[p].state =PROCESS_STATE_CALLED;
		pThread_params_chan ! processes[p].thread,ev,data ;
		 pThread_sync_chan ? eval(processes[p].thread),ptRes;
		if//-Begin of process.c\call_process:191-197
		:: (ptRes==PT_EXITED || ptRes==PT_ENDED || ev==PROCESS_EVENT_EXIT) ->
			printf("%d",p);
			isTerm[p] = 1;
			preNP = _nr_pr;//- Begin of process.c\call_process:194
			run exit_process(p,p,ret_chan_exit);
		    ret_chan_exit ? 0;
			(_nr_pr == preNP);//- End of process.c\call_process:194
			goto end; 
	   :: else -> processes[p].state = PROCESS_STATE_RUNNING;
	    	goto end; 
		fi;//-End of process.c\call_process:191-197
	:: else -> 
		   if 
		   :: processes[p].thread == NULL -> //repair2
				preNP = _nr_pr;
				run exit_process(p,p,ret_chan_exit);
				ret_chan_exit ? tmp;
				(_nr_pr == preNP);
		   :: else -> 
				skip;
		   fi;

	fi; //-- End of process.c\call_process:185-198
	end: sync_ch ! 0;
	
}//-End of process.c\call_process:174-199
//--- Begin of process.c\do_poll:224-238
proctype do_poll(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int np ;
	mtype: process_data_t data2; 
	int p;
	poll_requested=0;
	p=process_list;//-- Begin of process.c\do_poll:231 - 237
	do
	::(p==NULL) -> 
			break
    :: else -> 
		if //- Begin of process.c\do_poll:232-236
		::(processes[p].needspoll==1) ->
				processes[p].state = PROCESS_STATE_RUNNING; 
				processes[p].needspoll = 0;
				 np = _nr_pr; //- Begin of process.c\do_poll:235
				run call_process(p,PROCESS_EVENT_POLL,data2,ret_chan); 
				ret_chan ? 0;
				_nr_pr == np//- End of process.c\do_poll:235
		:: else ->skip
	    fi //- End of process.c\do_poll:232-236
		p= processes[p].next
	od//-- End of process.c\do_poll:231 - 237
 syn_chan ! 0
}//--- End of process.c\do_poll:224-238
proctype do_event(chan syn_chan)//--- process.c\do_event:245-299
{ 
	chan ret_chan = [0] of {int};
	int np,ev,receiver,rec,p,data;
	
	if//process.c\do_event:261-298
	:: (nevents==0) ->  skip
	:: else -> 
			ev = events[fevent].ev;	
			data = events[fevent].data; 
			receiver = events[fevent].p;
			rec = receiver;
			fevent = (fevent + 1) % PROCESS_CONF_NUMEVENTS;
			nevents = nevents - 1;
			if //-- Begin of process.c\do_event:276 - 297
			::(receiver==PROCESS_BROADCAST) ->
				p = process_list; //- Begin of process.c\do_event:277 - 285
				do
				::(p==NULL)   -> 
						break;
				:: else -> 
						if
						::(poll_requested) -> 
							np = _nr_pr;//-Begin of process.c\do_event:282
							run do_poll(ret_chan);
							ret_chan ? 0;
							np == _nr_pr//- End of process.c\do_event:282
						:: else 
						fi
						np = _nr_pr; //Begin of process.c\do_event:284
						run call_process(p,ev,data,ret_chan );
						ret_chan ? 0;
						np == _nr_pr;//End  of process.c\do_event:284
						p = processes[p].next
				od//- End of process.c\do_event:277 - 285
			:: else -> 
				if 
				::(ev==PROCESS_EVENT_INIT) -> 
						 if //repair1
						 :: processes_valid[receiver] == 1 ->
										processes[receiver].state = PROCESS_STATE_RUNNING; 
						  :: else 
						 fi
				:: else 
				fi
				np = _nr_pr;//Begin of process.c\do_event:296
				run call_process(receiver,ev,data,ret_chan);
				ret_chan ? 0;
				np == _nr_pr//End of process.c\do_event:296
			fi//-- End of process.c\do_event:276 - 297
	fi//process.c\do_event:261-298
	syn_chan ! 0
}//---End of  process.c\do_event:245-299
proctype process_run(chan syn_chan)//--- process.c\process_run:301-313
{
	chan ret_chan = [0] of {int};
	int np;
	if //-- process.c\process_run:305-307
	::(poll_requested) ->
			np = _nr_pr;
			run do_poll(ret_chan);
			ret_chan ? 0;
			np == _nr_pr
	:: else
	fi//-- End of process.c\process_run:305-307
	np = _nr_pr;//- Begin of process.c\process_run:310
	run do_event(ret_chan);
	ret_chan ? 0;
	np == _nr_pr;//-End  of process.c\process_run:310
	syn_chan ! (poll_requested+nevents)  //process.c\process_run:312
}	//--- End of process.c\process_run:301-31
proctype pThread()
{
	chan ret_chan = [0] of {int};
	int ev16; 
	int r;
	int rn2=1;
	int data;  int NP; int stCnt;
	Assign: pThread_params_chan  ? NULL,ev16,data;
	if
	:: ev16 == ASIGN_PTHREAD -> pThread_sync_chan ! _pid,PT_CREATED; 
	:: else -> goto Assign;
	fi;
	BEGIN: pThread_params_chan  ?  eval(_pid),ev16,data;
	if 
	:: ev16 == PROCESS_EVENT_INIT ->  skip;
	:: else -> goto BEGIN;
	fi;
	stCnt=0;
	Statements:  if
						:: stCnt < 5 -> skip;
						:: else -> goto PTEND;
						fi;
						
					 select ( r10 : 1 .. 4 );
					   if
					  :: (r10==1) -> goto PTEND;
					  :: (r10==2) -> goto rand_pr;
					  :: (r10==3) -> goto rand_ev;
					  :: (r10==4) -> goto PTWAIT;
					  fi;
					 
				rand_pr:NP=_nr_pr;
											run startRandomProcess(ret_chan);
											ret_chan ? 0;
											(NP== _nr_pr); 
											stCnt++;
											goto Statements;
								
					  rand_ev:  NP=_nr_pr; 
									run postRandomEvent(ret_chan); 
									ret_chan ? 0;
									(NP==_nr_pr); 
									stCnt++; 
									goto Statements;
					 
	PTWAIT:  pThread_sync_chan ! _pid,PT_WAITING;
							pThread_params_chan  ? eval(_pid),ev16,data 
							stCnt++;
							if 
							:: ev16 == THREAD_INIT -> goto BEGIN;
							:: else ->  goto Statements;;
							fi;
    	
   PTEND:		if 
						:: (1) -> pThread_sync_chan ! _pid,PT_ENDED; 
						:: (1) -> pThread_sync_chan ! _pid,PT_EXITED;
						fi;
						goto BEGIN; 
}

  active proctype ISR() 
 {
   chan ret_chan = [0] of {int};
   int p;
   run process_poll();
   newInterrupt:  if 
							 :: (_last != _pid) ->
									  atomic {
									    select( p : 0 .. nProcesses-1); 
										printf("%d",p);
										// poll the process
										poll_sync_chan ! p;
										poll_sync_chan ? NULL
									}
							fi
  goto newInterrupt
 }

//*************************************************** LTL formula

#define isInNoneState(p) (processes[p].state == PROCESS_STATE_NONE)
#define isInRunningState(p)  (processes[p].state==PROCESS_STATE_RUNNING)
#define isInCalledState(p)  (processes[p].state==PROCESS_STATE_CALLED)
#define isInProcessList(p)  (processes_valid[p] == 1)
#define isActive(p) (isInRunningState(p) || isInCalledState(p))
#define needspollProc(p) (processes[p].needspoll==1)
#define isTerminatedProc(p) (isTerm[p] ==1)
#define ev_exit PROCESS_EVENT_EXIT
#define receivedExitEvent(p) (calledProcess_id == p && sent_ev == ev_exit )
#define pollRequested() (poll_requested == 1)


//****************************************** Verified requirements
#define p1(p) (isInCalledState(p) && X(isInNoneState(p))  -> X(<>(!isInProcessList(p))))
#define p2(p) (isInProcessList(p) && X(!isInProcessList(p))  -> isInNoneState(p))
#define p3(p) (!isInProcessList(p) && X(isInProcessList(p)) -> X(<>(isInRunningState(p)) ))
#define p4(p) (!needspollProc(p) && X(needspollProc(p)) -> isActive(p))

//ltl prop1 {[]( p1(0) && p1(1) && p1(2) && p1(3) && p1(4)) }// liveness: ok
//State-vector 1496 byte, depth reached 5064, errors: 0
//   453209 states, stored (497982 visited)
 // 1255730 states, matched
 // 1753712 transitions (= visited+matched)
//   651.778 equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//11.48
//************
//ltl prop2 {[]( p2(0) && p2(1) && p2(2) && p2(3) && p2(4)) }//safety: ok 
//State-vector 1492 byte, depth reached 4415, errors: 0
//  501211 states, stored
//  1225663 states, matched
//  1726874 transitions (= stored+matched)
//  715.076	equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//9.56
//************
//ltl prop3 {[](p3(0) && p3(1) && p3(2) && p3(3) && p3(4)) } //liveness: ok ,
//State-vector 1496 byte, depth reached 4641, errors: 0
 //  502372 states, stored (503301 visited)
//  1205192 states, matched
//  1708493 transitions (= visited+matched)
//  722.482 equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//11.15
//************
//ltl prop4 {[]( p4(0) && p4(1) && p4(2) && p4(3) && p4(4))} // safety: ok 
//State-vector 1492 byte, depth reached 4951,, errors: 0
  // 504384 states, stored
 // 1212920 states, matched
 // 1717304 transitions (= stored+matched)
//  719.603	equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//9.38
//************

  
//****************************************** Detected flaws
#define p5(p) ((isInNoneState(p) && ( X(isInRunningState(p))) ) -> !needspollProc(p) )
#define p6(p) ( isTerminatedProc(p)  -> (<> isInNoneState(p)))
#define p7(p) ((isInRunningState(p) && receivedExitEvent(p)) -> (<>(isInNoneState(p)  )))
#define p8(p) (isActive(p) -> isInProcessList(p))
#define p9(p) ((isActive(p) && needspollProc(p)) -> isInProcessList(p))
#define p10(p) ( pollRequested() && X(!pollRequested()) && isActive(p)  && needspollProc(p) -> <>(!needspollProc(p)))
#define p11(p) (isInNoneState(p) -> <>(!needspollProc(p)))
#define p12(p) (!isInProcessList(p) -> (!needspollProc(p)))

//ltl prop5 {[](p5(0) && p5(1) && p5(2) && p5(3) && p5(4) ) } //safety: error
//State-vector 1492 byte, depth reached 4044, errors: 0
 //  482986 states, stored
 // 1209739 states, matched
 // 1692725 transitions (= stored+matched)
//   689.075	equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//9.55
//************

ltl prop6 { [] (p6(0) && p6(1) && p6(2) && p6(3) && p6(4)  )} //liveness: error
//State-vector 1468 byte, depth reached 4470, errors: 0
//   420519 states, stored (490580 visited)
//  1390455 states, matched
 // 1881035 transitions (= visited+matched)
//  593.536				equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//11.77
//************
//ltl prop7 { [] (p7(0) && p7(1) && p7(2) && p7(3) && p7(4))} // liveness: error
//State-vector 1504 byte, depth reached 4221, errors: 0
 //  485853 states, stored
 // 1216039 states, matched
  //1701892 transitions (= stored+matched)
//  702.432					equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//11.67
//************
//ltl prop8 {[]( p8(0) && p8(1) && p8(2) && p8(3) && p8(4)) }//Saftey: ok
//State-vector 1492 byte, depth reached 4264, errors: 0
 //  484171 states, stored
 // 1211732 states, matched
//  1695903 transitions (= stored+matched)
//  690.765					equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//11.56
//************
//ltl prop9 {[]( p9(0) && p9(1) && p9(2) && p9(3) && p9(4))} // Saftey: ok
//State-vector 1496 byte, depth reached 4119,, errors: 0
//    484825 states, stored
//  1214362 states, matched
//  1699187 transitions (= stored+matched)
//  697.247	equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//13.47
//************
//ltl prop10 {[](p10(0) && p10(1) && p10(2) && p10(3) && p10(4))} //liveness: error 
//State-vector 1496 byte, depth reached 4598, errors: 0
 //  498036 states, stored
 // 1223595 states, matched
//  1721631 transitions (= stored+matched)
//  716.246	equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//13.58
//************
//ltl prop11 {[]( p11(0) && p11(1) && p11(2) && p11(3) && p11(4) )} // liveness: error
//State-vector 1496 byte, depth reached 4286, errors: 0
 //  479024 states, stored (481945 visited)
 // 1209899 states, matched
 // 1691844 transitions (= visited+matched)
//  688.904 equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//11.31
//************
//ltl prop12 {[]( p12(0) && p12(1) && p12(2) && p12(3) && p12(4) )} // safety: error
//State-vector 1492 byte, depth reached 4264, errors: 0
 //  484171 states, stored
 // 1211732 states, matched
 // 1695903 transitions (= stored+matched)
//   690.765 equivalent memory usage for states (stored*(State-vector + overhead))
// 242.879	total actual memory usage
//8.03 s
//************




