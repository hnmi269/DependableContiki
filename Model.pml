#define max_nProcesses 5
#define PROCESS_CONF_NUMEVENTS  32 
#define PROCESS_BROADCAST 1000
#define max_nAutoStartProcesses 30
#define PROCESS_ERR_FULL 1000
#define NULL 1000
//*****************************************Verificaton
 #define desiredProcess_id  6
#define desiredEvent PROCESS_EVENT_EXIT
int desiredP_id = 4;
int validCnt;
//*****************************************
mtype: process_event_t = {PROCESS_EVENT_NONE , PROCESS_EVENT_INIT, PROCESS_EVENT_POLL, PROCESS_EVENT_EXIT, 
PROCESS_EVENT_SERVICE_REMOVED, PROCES_EVENT_CONTINUE, PROCESS_EVENT_MSG, PROCESS_EVENT_EXITED,
PROCESS_EVENT_TIMER, PROCESS_EVENT_COM, PROCESS_EVENT_MAX,ASIGN_PTHREAD,THREAD_INIT};

mtype: boolType = {False,True};
mtype: proc_state= {PROCESS_STATE_NONE,PROCESS_STATE_CALLED,PROCESS_STATE_RUNNING};

mtype: ptResult = { PT_WAITING, PT_YIELDED, PT_EXITED, PT_ENDED,PT_CREATED };
int poll_requested ;
int nevents;
int fevent;

int nProcesses;//new added

typedef process {
	int next;
	byte name[9];
	int thread;
	byte needspoll;
	mtype: proc_state state;
};
process processes[max_nProcesses];
int processes_valid[max_nProcesses]; //Verificaton
int autostart_processes[max_nAutoStartProcesses];

int nAutoStartProcesses ;



int process_list = NULL;
int process_current = NULL;

//--- process.c:62-66
typedef event_data {
 	mtype: process_event_t ev;
	mtype: process_data_t   data;       
	int p;
}
event_data events[PROCESS_CONF_NUMEVENTS];



chan pThread_params_chan = [1] of {short,int , int };
chan pThread_sync_chan = [0] of {int,mtype:ptResult};
chan poll_sync_chan = [0] of {int};

chan ret_chan_thread = [0] of {mtype: ptResult};

int calledProcess_id= NULL;
int ExitedProcess_id= NULL;
//int terminatedProcess_id= NULL;
int isTerminated[nProcesses];
int isCalled[nProcesses];
int lastEvent[nProcesses];
int  sent_ev;
int eventCnt;

mtype:process_data_t ={nill,killed_p};
process desiredProcess; //Verificaton

									
proctype  PT_INIT(int p;chan syn_chan) 
{
    if 
	::(processes[p].thread==NULL) -> 
			skip;
	:: else -> pThread_params_chan ! processes[p].thread,THREAD_INIT , 0 ; 
	fi		
	isTerminated[p] = 0;
	syn_chan ! 0;
} 
int rn;
		//active proctype randn()
		//{
				     
		//}
	int r10;		
		int r11;	
proctype  _Process(int p;chan syn_chan)    
{

  mtype:ptResult res1; 
  int r;
 
	begin: processes[p].name[0]  = 'P';  
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
	
	//select( r11 : 0 .. 1);
	
//    do 
//	:: rn==0 -> rn++;
//    :: rn==1 -> rn--;
//	:: break;
//	od
	// if   
	// :: (rn==1) -> processes[p].thread = NULL
	// :: (rn==0) -> //atomic{ 
					//pThread_params_chan ! NULL,ASIGN_PTHREAD , 0 ; 
				//	run pThread(); 
					//pThread_sync_chan  ? processes[p].thread,res1;
					//}
	//fi;
	//select( r11 : 0 .. 1);
	     
        if
		:: r11 != 0 -> processes[p].thread = NULL; r11=0;
		:: r11 != 1 -> pThread_params_chan ! NULL,ASIGN_PTHREAD , 0 ; 
							 run pThread(); 
							 pThread_sync_chan  ? processes[p].thread,res1; r11=1;
		fi;

	processes_valid[p] = 0; 
	//if //Verificaton
	//:: p==desiredP_id ->
	//	desiredProcess.state = processes[p].state;
	//	desiredProcess.needspoll =processes[p].needspoll;
	//	desiredProcess.thread = processes[p].thread;
	//::else -> skip;
//	fi;
	end: syn_chan ! 0;
}
									   
proctype Processes_initialization(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int p;
	int r,r1;
	
			//select ( r10 : 0 .. 1);
  begin: do
   ::   (p < max_nProcesses) ->
			run _Process(p,ret_chan); 
			ret_chan ? 0;
			//select ( r10 : 0 .. 1);
			if 
			::  (nAutoStartProcesses < max_nAutoStartProcesses)  ->  
						autostart_processes[nAutoStartProcesses] = p;  
						nAutoStartProcesses = nAutoStartProcesses+1;	
			:: (1) -> skip;
			fi; 
			p++;
			//select ( r10 : 0 .. 1);
	
 :: (1)-> nProcesses = p; 
				break; 
 od;
 
 //do 
	//	    :: rn==0 -> rn++;
	//		:: rn==1 -> rn--;
	//	    :: break;
//			od
 //do
 //  ::  rn==0 && (p < max_nProcesses) ->
	//		run _Process(p,ret_chan); 
	//		ret_chan ? 0;
	//		do 
	//	    :: rn==0 -> rn++;
	//		:: rn==1 -> rn--;
	//	    :: break;
	//		od
	//		if 
	//		:: (rn==0) && (nAutoStartProcesses < max_nAutoStartProcesses)  ->  
	//					autostart_processes[nAutoStartProcesses] = p;  
	//					nAutoStartProcesses = nAutoStartProcesses+1;	
	//		:: (rn==1) || (nAutoStartProcesses >= max_nAutoStartProcesses) -> skip;
	//		fi; 
	//		p++;
	//		do 
	//	    :: rn==0 -> rn++;
	//		:: rn==1 -> rn--;
	//	    :: break;
	//		od
	
 //:: (rn==1) || (p >= max_nProcesses)-> nProcesses = p; 
			//	break; 
 //od;
 end: syn_chan ! 0;
}
	int rn1=3;										
proctype randomEvent(chan syn_chan)  
{
	int ev;
	int r;
	//do  
	//:: rn1>=3 && rn1 <= 12 -> rn1++;
	//:: rn1>3 && rn1 <= 13 -> rn1--;
	//:: break;
	//od
	//if 
	//:: (rn1==12) -> ev=PROCESS_EVENT_INIT;
	//:: (rn1==10) -> ev=PROCESS_EVENT_EXIT;
	//:: (rn1==13) -> ev=PROCESS_EVENT_NONE;
	//:: (rn1==11) -> ev=PROCESS_EVENT_POLL;
	//:: (rn1==9) -> ev=PROCESS_EVENT_SERVICE_REMOVED;
//	:: (rn1==8) -> ev=PROCES_EVENT_CONTINUE;
	//:: (rn1==7) -> ev=PROCESS_EVENT_MSG;
	//:: (rn1==6) -> ev=PROCESS_EVENT_EXITED;
	//:: (rn1==5) -> ev=PROCESS_EVENT_TIMER;
//	:: (rn1==4) -> ev=PROCESS_EVENT_COM;
//	:: (rn1==3) -> ev=PROCESS_EVENT_MAX;
//	fi;
	
	//select( rn1 : 3 .. 13);
	// if 
	//:: (r==12) -> ev=PROCESS_EVENT_INIT;
	//:: (r==10) -> ev=PROCESS_EVENT_EXIT;
	//:: (r==13) -> ev=PROCESS_EVENT_NONE;
//	:: (r==11) -> ev=PROCESS_EVENT_POLL;
//	:: (r==9) -> ev=PROCESS_EVENT_SERVICE_REMOVED;
//	:: (r==8) -> ev=PROCES_EVENT_CONTINUE;
	//:: (r==7) -> ev=PROCESS_EVENT_MSG;
//	:: (r==6) -> ev=PROCESS_EVENT_EXITED;
//	:: (r==5) -> ev=PROCESS_EVENT_TIMER;
//	:: (r==4) -> ev=PROCESS_EVENT_COM;
	//:: (r==3) -> ev=PROCESS_EVENT_MAX;
	// fi;
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
proctype randomProcess(int pocT;int fromp;chan syn_chan)
{
	//int rp;
	
	//do  
//	::((p==(fromp-1)) && p < (nProcesses-2)) -> p=p+2;
	//::((p >= 0) && p < (fromp-1)) -> p++;
//	:: ((p==fromp) && (p < nProcesses -1)) -> p++;
//	::((p > fromp) && p < (nProcesses-1)) -> p++;
//	:: (pocT == 3) -> p = PROCESS_BROADCAST; break;
//	:: (p > fromp || p < fromp) && (p < (nProcesses-1)) -> break;
//	od;
	if
	:: (pocT==3) ->
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

//int r_p = 0;
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
  }
  proctype process_post(int p;int ev;chan syn_chan)
 {
	int snum;
	if  
	:: (nevents==PROCESS_CONF_NUMEVENTS) ->
		skip;
	:: else ->  
	      snum = (fevent + nevents) % PROCESS_CONF_NUMEVENTS;
         events[snum].ev = ev;
         events[snum].p = p;
          nevents++;
	fi;
	syn_chan ! 0;
}		
proctype postRandomEvent(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int r_p = 0;
	int np_new4;
	int ev;
	int r;
	
		//np_new4 = _nr_pr; 
		//run randomProcess(3,process_current,ret_chan);
		//ret_chan ? r_p;
		//np_new4 == _nr_pr; 
	//do
	//:: r_p = 0;
	//:: r_p = 1;
	//:: r_p = 2;
	//:: r_p = 3;
	//:: r_p = 4;
//:: r_p = PROCESS_BROADCAST;
//	::break;
	//od
	
	np_new4 = _nr_pr; 
	run randomEvent(ret_chan); 
	ret_chan ? ev;
	(np_new4 == _nr_pr); 

	select( r_p : 0 .. nProcesses);
	r_p = (r_p==nProcesses->1000:r_p);
	postType: if 
	:: r_p==PROCESS_BROADCAST ->
			 np_new4 = _nr_pr; 
					run process_post(r_p,ev,ret_chan);
					ret_chan ? 0;
						(np_new4 == _nr_pr);
		 
	:: else ->
			//do 
		   // :: rn==0 -> rn++;
			//:: rn==1 -> rn--;
		  // :: break;
			//od
			//select( r : 0 .. 1);
			if 
			:: (1) -> 
						np_new4 = _nr_pr; 
						run process_post(r_p,ev,ret_chan);
						ret_chan ? 0;
						(np_new4 == _nr_pr);
			:: (1) -> 
						 np_new4 = _nr_pr;
						 run process_post_synch(r_p,ev,ret_chan);
						 ret_chan ? 0;
						 (np_new4 == _nr_pr);
			fi 
	fi;
	end: syn_chan ! 0;
}
proctype process_start(int p; chan syn_chan)
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
		validCnt++; //Verificaton
		process_list=p;
		processes[p].state= PROCESS_STATE_RUNNING;
		 np_new5 = _nr_pr;
		run PT_INIT(p,ret_chan); 
		ret_chan ? 0;
		 (np_new5 == _nr_pr);
		 np_new5 = _nr_pr;
		run process_post_synch(p,PROCESS_EVENT_INIT,ret_chan);
		ret_chan ? 0;
		 (np_new5 == _nr_pr);
	fi;
	syn_chan ! 0;
  }									  
proctype startRandomProcess(chan syn_chan)
{
chan ret_chan_1 = [0] of {int};
chan ret_chan_2 = [0] of {int};
int r_p;
int np_new3;

//if
//::nProcesses > 1 ->
//	np_new3 = _nr_pr;	
//	run randomProcess(1,process_current,ret_chan_1); 	
//	ret_chan_1 ? r_p;	
	//(np_new3 == _nr_pr);
	
//	do
//	:: r_p = 0;
//	:: r_p = 1;
//	:: r_p = 2;
//	:: r_p = 3;
//	:: r_p = 4;
//	:: r_p != PROCESS_BROADCAST -> break;
//	od

begin:	select (r_p : 1 .. nProcesses);
	np_new3 = _nr_pr;						
	run process_start(r_p-1,ret_chan_2);	
	ret_chan_2 ? 0;	
	(np_new3 == _nr_pr);	
//:: else -> skip;
//fi;
	

end: syn_chan ! 0;		
}

 proctype process_poll()
 {
	int p;
	begin:  atomic{
	poll_sync_chan ? p;
    if 
    ::(p==NULL) -> 
		skip;
	:: else -> 
		 if  
         ::((processes[p].state==PROCESS_STATE_RUNNING)||(processes[p].state==PROCESS_STATE_CALLED)) -> 
					processes[p].needspoll = 1;
	                poll_requested = 1;
		:: else -> skip;
         fi; 
   fi
   poll_sync_chan ! NULL;
  }
   goto begin;
 }
 
proctype autostart_start(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int p;
	int np_new2;
	int i;
	do 
	:: (p < nAutoStartProcesses) -> 
					np_new2=_nr_pr;
					i = autostart_processes[p];
				    run process_start(i,ret_chan);
					ret_chan ? 0;
					(np_new2 == _nr_pr);
					p++;
	::	else -> break;
	od
	syn_chan ! 0;
  }					

proctype process_is_running(int p;chan syn_chan)
{
int result;
	if 
	:: (processes[p].state==PROCESS_STATE_RUNNING) || (processes[p].state==PROCESS_STATE_CALLED) -> result =1;
	:: else -> result = 0;
	fi;
	//int result=(processes[p].state != PROCESS_STATE_NONE);
	syn_chan ! result;
}
proctype exit_process(int p; int fromProcess; chan sync_ch)
{  
	chan ret_chan = [0] of {int};
	int preNP12; 
	mtype: ptResult ptRes; 
	//mtype:process_data_t 
	int data;  
	int q; 
	int result;
	int old_current;
	begin: old_current = process_current;
	q = process_list; 
	do 
	:: (q==NULL) || (q==p) -> break;
	::else -> q = processes[q].next;
   od;
	if 
	:: (q==NULL ) -> goto end;
	:: else -> skip;
	fi;
	preNP12=_nr_pr;
	run process_is_running(p,ret_chan);
	ret_chan ? result;
	(_nr_pr == preNP12);
t:	if
	:: ( result) ->   
		 ExitedProcess_id=p; 
	      processes[p].state = PROCESS_STATE_NONE;   
		// processes[p].needspoll = 0; //**
		
		q = process_list;
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
		od;
		if 
		::p==fromProcess ->  
				skip;
		:: else -> 
				process_current = p;
				pThread_params_chan ! processes[p].thread,PROCESS_EVENT_EXIT, data;
				pThread_sync_chan ? eval(processes[p].thread),ptRes;
		fi;
	:: else -> skip;
	fi;
	if 
	::p==process_list ->  
		//atomic{
	     process_list=processes[process_list].next; 
	     processes_valid[p] = 0; 
		 validCnt--; //Verificaton
		// }
	:: else ->  q = process_list; 
			do
			:: q==NULL -> 
					break;
			::  else -> 
					if 
				::processes[q].next==p -> 
									//atomic{
									processes[q].next = processes[p].next; 
									processes_valid[p] = 0; 
									validCnt--; //Verificaton
									//}
									break;
				:: else -> skip;
				fi ;
				q = processes[q].next;
			od 
	fi; 
	end: process_current = old_current ;
	 sync_ch ! 0;
}
int call_process_id;
proctype  call_process(int p;int  ev; int data; chan sync_ch)   
{ 
	chan ret_chan_exit = [0] of {int};
	//call_process_id = _pid;
	int preNP;
	int p1 = p;
	//isCalled[p] = 1;
	//lastEvent[p] = ev;
	calledProcess_id = p;  
	sent_ev = ev;  
	int tmp;
	mtype:ptResult ptRes; 
	begin: if 
	:: (processes[p].state == PROCESS_STATE_RUNNING && processes[p].thread != NULL) ->
		process_current = p;
		processes[p].state =PROCESS_STATE_CALLED;
		//if
		//:: p==desiredP_id -> desiredProcess.state = processes[p].state;
		//::else -> skip;
		//fi;
		pThread_params_chan ! processes[p].thread,ev,data ;
		 pThread_sync_chan ? eval(processes[p].thread),ptRes;
		thread_result: if
		:: (ptRes==PT_EXITED || ptRes==PT_ENDED || ev==PROCESS_EVENT_EXIT) ->  
				//terminatedProcess_id = p;  
				
				isTerminated[p] = 1;
			 preNP = _nr_pr;
			run exit_process(p,p,ret_chan_exit);
		     ret_chan_exit ? 0;
			(_nr_pr == preNP);
			goto end; 
	   :: else -> processes[p].state = PROCESS_STATE_RUNNING;
			//if
			//:: p==desiredP_id -> desiredProcess.state = processes[p].state;
			//::else -> skip;
			//fi;
	    	goto end; 
		fi;
	:: else -> 
			//if 
			//:: processes[p].thread == NULL -> //**
			//	preNP = _nr_pr;
			//	run exit_process(p,p,ret_chan_exit);
			//	ret_chan_exit ? tmp;
			//	(_nr_pr == preNP);
		   //:: else -> 
		   skip;
		   //fi;
	fi; 
	
	end:  sync_ch ! 0;
	
}
	
byte needs = 1;
int N = 1000;
proctype do_poll(chan syn_chan)
{
chan ret_chan = [0] of {int};
int preNP1 ;
mtype: process_data_t data2; 
	int p;
	poll_requested=0;
	eventCnt=0;
	p=process_list;
	do
	::(p==NULL) -> 
			break;
    :: else -> 
		if 
		::(processes[p].needspoll==1) ->
				processes[p].state = PROCESS_STATE_RUNNING; 
				processes[p].needspoll = 0;
				//if
				//:: p==desiredP_id -> 
				//	desiredProcess.state = processes[p].state;
				//	desiredProcess.needspoll =processes[p].needspoll;
				//::else -> skip;
				//fi;
				 preNP1 = _nr_pr;
				run call_process(p,PROCESS_EVENT_POLL,data2,ret_chan); 
				ret_chan ? 0;
				(_nr_pr == preNP1);
		:: else -> skip;
	    fi; 
		p= processes[p].next;
	od;
	
 syn_chan ! 0;
}
int z;
int Ev_Init = 12;
proctype do_event(chan syn_chan)
{ 
	chan ret_chan = [0] of {int};
	int np_new6;
	int ev;
	int receiver; 
	int rec;
	int p;
	int data;
    	if
	    :: (nevents==0) ->  skip;
	    :: else -> 
	    ev = events[fevent].ev;	
		data = events[fevent].data; 
		receiver = events[fevent].p;
		rec = receiver;
		fevent = (fevent + 1) % PROCESS_CONF_NUMEVENTS;
    	nevents = nevents - 1;
		eventCnt = (poll_requested -> eventCnt+1 : 0);
		if 
		::(receiver==PROCESS_BROADCAST) ->
			p = process_list; 
			do
			::(p==NULL)   -> 
					break;
			:: else -> 
						if
					::(poll_requested==1) -> 
						np_new6 = _nr_pr;
						run do_poll(ret_chan);
						ret_chan ? 0;
						(np_new6 == _nr_pr);
					:: else -> skip;
					fi;
					np_new6 = _nr_pr; 
					run call_process(p,ev,data,ret_chan );
					ret_chan ? 0;
					(np_new6 == _nr_pr);
					p = processes[p].next;
			od
		:: else -> 
			if 
			::(ev==PROCESS_EVENT_INIT) -> 
					//if //
					//:: processes_valid[receiver] == 1 ->
						processes[receiver].state = PROCESS_STATE_RUNNING; 
					//:: else -> skip;
				//	fi;
					
			:: else -> skip;
			fi;
			np_new6 = _nr_pr;
			run call_process(receiver,ev,data,ret_chan);
			ret_chan ? 0;
			(np_new6 == _nr_pr);
		fi;
	fi;
	syn_chan ! 0;
}
	// int preNP7;	
proctype process_run(chan syn_chan)
{
	chan ret_chan = [0] of {int};
	int np_new7;
	if 
	::(poll_requested==1) ->
			np_new7 = _nr_pr;
			run do_poll(ret_chan);
			ret_chan ? 0;
			(np_new7 == _nr_pr);
	:: else -> skip
	fi;
	np_new7 = _nr_pr;
	run do_event(ret_chan);
	ret_chan ? 0;
	(np_new7 == _nr_pr);
		syn_chan ! 0;
}			
proctype main()
{
     chan ret_chan =[0] of {int}; 
	 byte np_new1;
	 //run ISR();
	 np_new1 = _nr_pr;
	 run autostart_start(ret_chan);
	 ret_chan ? 0;
	(np_new1==_nr_pr);
      do
	  :: (1) -> 
			np_new1 = (_nr_pr);
			 run process_run(ret_chan);
			  ret_chan ? 0;
			 (np_new1==_nr_pr);
	  od
}
init {
chan ret_chan = [0] of {int};
    // desiredP_id = desiredP_id;
	run Processes_initialization(ret_chan);
	ret_chan ? 0;
//run ISR();

	run main();
}

proctype pThread()
{
	chan ret_chan = [0] of {int};
	//mtype: process_event_t 
	int ev16; 
	int r;
	int rn2=1;
	//mtype: process_data_t 
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
						//do 
						//:: rn2>=1 && rn2 <= 3 -> rn2++;
						//:: rn2>1 && rn2 <= 4 -> rn2--;
						//:: break;
						//od
					 select ( r10 : 1 .. 4 );
					   if
					  :: (r10==1) -> goto PTEND;
					  :: (r10==2) -> goto rand_pr;
					  :: (r10==3) -> goto rand_ev;
					  :: (r10==4) -> goto PTWAIT;
					  fi;
					  //if
					  //:: (rn2==1) -> goto PTEND;
					 // :: (rn2==2) -> goto rand_pr;
					 // :: (rn2==3) -> goto rand_ev;
					 // :: (rn2==4) -> goto PTWAIT;
					 // fi;
					  
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
    	
   PTEND:		//select ( r10 : 0 .. 1 );
						if 
						:: (1) -> pThread_sync_chan ! _pid,PT_ENDED; 
						:: (1) -> pThread_sync_chan ! _pid,PT_EXITED;
						fi;
						//if 
						//:: (1) -> pThread_sync_chan ! _pid,PT_ENDED; 
						//:: (1) -> pThread_sync_chan ! _pid,PT_EXITED;
						//fi;
						goto BEGIN; 
}

  active proctype ISR() 
 {
   chan ret_chan = [0] of {int};
   int p;
   run process_poll();
   newInterruption:  if 
							 :: (_last != _pid) ->
									  atomic {
									    //select( p : 1 .. nProcesses);
										//p=0
										do  //Select a random process
										:: (p >= 0 && p < nProcesses-1) -> p++;
										:: break; 
										od;
										
										// poll the process
										poll_sync_chan ! p;
										poll_sync_chan ? NULL;
									}
							fi;
  goto newInterruption;
 }
 

#define pollRequested() (poll_requested == 1)
#define isAssignedThread(p) (processes[p].thread != NULL)
//#define isCreated(p) (processes[p].thread == NULL || processes[p].thread > 0)
#define isInProcessList(p)  (processes_valid[p] == 1)
#define isInNoneState(p) (processes[p].state == PROCESS_STATE_NONE)
#define isCreated(p) (processes[p].state > 0)
#define isInRunningState(p)  (processes[p].state==PROCESS_STATE_RUNNING)
#define isInCalledState(p)  processes[p].state==PROCESS_STATE_CALLED
#define isActive(p) (isInRunningState(p) || isInCalledState(p))
#define needspollProc(p) (processes[p].needspoll == 1)
#define isEmptyProcList() (validCnt == 0)
#define lastReceivedEvent(p,ev) (calledProcess_id == p && sent_ev == ev )
#define calledProc(p) (calledProcess_id == p)
#define lastKilledProcess(p) (ExitedProcess_id == p)
#define isTerminatedProc(p) (isTerminated[p] ==1)
#define notIsTerminatedP(p) (isTerminated[p] != 1)
#define isCreated1(p)  (processes[p].state == PROCESS_STATE_NONE || processes[p].state == PROCESS_STATE_RUNNING || processes[p].state == PROCESS_STATE_CALLED)
#define isRunning(p) (processes[p].state == PROCESS_STATE_RUNNING || processes[p].state == PROCESS_STATE_CALLED)

#define p0(p) (isInNoneState(p) -> <>(!needspollProc(p)))
#define p1(p) (!isInProcessList(p) -> (!needspollProc(p)))
#define p2(p) (isInCalledState(p) && X(isInNoneState(p))  -> X(<>(!isInProcessList(p))))
#define p3(p) ((isInNoneState(p) && ( X(isInRunningState(p))) ) -> X( !needspollProc(p) ))// thread != NULL && ISR enable
#define p4(p) ((!isInProcessList(p) && ( X(isInProcessList(p))) ) -> X( !needspollProc(p) ))// thread != NULL && ISR enable
#define p6(p) ((!isTerminatedProc(p) && X(isTerminatedProc(p))) -> (<> isInNoneState(p)))
#define p7(p,ev) ((isInRunningState(p) && lastReceivedEvent(p,ev)) -> (<>(isInNoneState(p)  )))
#define p8(p) (!isInProcessList(p) && X(isInProcessList(p)) -> X(<>(isInRunningState(p)) ))
#define p9(p) (isActive(p) -> isInProcessList(p))
#define p10(p) (isInProcessList(p) && X(!isInProcessList(p))  -> X(isInNoneState(p)))
#define p11(p) (!needspollProc(p) && X(needspollProc(p)) -> X(isInProcessList(p)))
#define p12(p) (!needspollProc(p) && X(needspollProc(p)) -> X(isActive(p)))
#define p13(p) (isInRunningState(p) && X(calledProc(p)) -> (<>(isInCalledState(p))))
#define p14(p) ((!isInProcessList(p) && ( X(isInProcessList(p))) ) -> X( isInNoneState(p) ))
#define p15(p) (isActive(p)  && needspollProc(p) && pollRequested() && X(!pollRequested()) -> X(X(<>(!needspollProc(p)))))
#define p16(p) (!isAssignedThread(p) && isInRunningState(p) && calledProcess_id==p -> X([](isInRunningState(p))) )//thread==NULL

 ltl prop0 {[]( p0(0) && p0(1) && p0(2) && p0(3) && p0(4) )} // liveness: error->cycle
 ltl prop1 {[]( p1(0) && p1(1) && p1(2) && p1(3) && p1(4) )} // safety: error->assertion violated
 ltl prop2 {[]( p2(0) && p2(1) && p2(2) && p2(3) && p2(4)) }// ok 
 ltl prop3 {[](p3(0) && p3(1) && p3(2) && p3(3) && p3(4) ) } //liveness: error ->assertion  
ltl prop4 {[](p4(0) && p4(1) && p4(2) && p4(3) && p4(4) ) } //liveness: error ->assertion 
ltl prop5 {[](pollRequested() && X(!pollRequested()) -> X(eventCnt < 2))}//safety: ok 
ltl prop6 { [] (p6(0) && p6(1) && p6(2) && p6(3) && p6(4))} //error
 ltl prop7 { [] (p7(0,PROCESS_EVENT_EXIT) && p7(1,PROCESS_EVENT_EXIT) && p7(2,PROCESS_EVENT_EXIT) && p7(3,PROCESS_EVENT_EXIT) && p7(4,PROCESS_EVENT_EXIT))} // liveness: error->cycle
 ltl prop8 {[](p8(0) && p8(1) && p8(2) && p8(3) && p8(4)) } //liveness: ok ,
 ltl prop9 {[]( p9(0) && p9(1) && p9(2) && p9(3) && p9(4)) }//safety: error ->assertion
 ltl prop10 {[]( p10(0) && p10(1) && p10(2) && p10(3) && p10(4)) }//safety: ok 
ltl prop11 {[]( p11(0) && p11(1) && p11(2) && p11(3) && p11(4))} // safety: error ->assertion
ltl prop12 {[]( p12(0) && p12(1) && p12(2) && p12(3) && p12(4))} // safety: ok 
ltl prop13 {[](p13(0) && p13(1) && p13(2) && p13(3) && p13(4))} //liveness: error->cycle,
ltl prop14 {[](p14(0) && p14(1) && p14(2) && p14(3) && p14(4))} // safety: error
ltl prop15 {[](p15(0) && p15(1) && p15(2) && p15(3) && p15(4))} //liveness: error
 ltl prop16 {[](p16(0) && p16(1) && p16(2) && p16(3) && p16(4))}//liveness: ok 




