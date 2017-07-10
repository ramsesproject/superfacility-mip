# eScienceNew.mod - AMPL model
# AMPL model for assigning data analysis tasks to compute resources 
#
# Convention: Parameters, Sets, Constants are UpperCase, 
#             variables, objectives and constraints and lowerCase
#
# Created by Sven Leyffer, Argonne National Laboratory, May/June 2017
###############################################################333####

# ... definition of sets
set Sites;                               # ... science sites
set Resources;                           # ... compute resources
set TransNodes;                          # ... set of transmission nodes
set Nodes := Sites union Resources union TransNodes ordered;
set Links within (Nodes cross Nodes);    # ... set of all links (with a unique direction)
set JobIds;                              # ... set of job identifiers
set Jobs within JobIds cross Sites;      # ... links JobIds and Sites
set Time;                                # ... discretized time
param numPaths{Sites,Resources};         # ... number of paths between an OD pairs
set Paths{s in Sites, r in Resources, 1..numPaths[s,r]} within Links;


# ... input parameters and constants
param T >=1 default card(Time);

param SiteName{Jobs};                    # ... only for entertainment
param T0{Jobs};                          # ... time job is entered into queue 
param TD{Sites cross Resources};         # ... fixed delay on allocation of site to resource
param NumNodes{Jobs};                    # ... number of nodes requested for job
param RunTime{Jobs};                     # ... expected run time for job
param DataSize{Jobs};                    # ... data size of job
param ComputeBudget > 0, integer;        # ... maximum compute (nodes) budget
param MaxDelayMult{Jobs} > 0, default 2; # ... maximum multiple delay of RunTime
param Bw{Links} >= 0, default 2500;      # ... maximum capacity of link
param BwMult >=0, default 10; 			 # ... time step (multiplier)
#param load{Time} >= 0, default 0;
#param compLoad{Time} >= 0, default 0;
#param dataLoad{Time} >= 0, default 0;
param Perc >=0;
param SlowDown >=1;
param M >=0, default max{(j,s) in Jobs}((T - T0[j,s])/RunTime[j,s]); 				 #big M for the 
# ... variables
var c{Resources} >= 0;                    # ... capacity of resource (INTEGER?)
var x{(j,s) in Jobs,Resources,(T0[j,s]+1)..(T-RunTime[j,s])} binary;        # ... = 1, iff job j arrives at resource r at time t
#var y{(j,s) in Jobs,Resources,(T0[j,s]+1)..T};               # ... = 1, iff job j running on resource r at time t (implied binary)
var lambda{(j,s) in Jobs, r in Resources, 1..numPaths[s,r],
(T0[j,s])..(T-RunTime[j,s]-1)} >= 0, <= 1; #!!!
                                          # ... fraction of job j sent to resource r at time t on path
var cap{(k,l) in Links} >= 0, <= BwMult*Bw[k,l]; # ... capacity of link (INTEGER?)
var z{(j,s) in Jobs, r in Resources, 1..numPaths[s,r]} binary;
                                          # ... = 1, iff transfer of job j from s to r along path p
#var sLinks{Links,Time} >=0; 			  # ... maximum slack on the link capacities
#var sComp >=0; 							  # ... maximum slack on compute budget
#var sDelay{Jobs} >=0; 					  # ... maximum slack on delay
var w{Jobs} binary;

# ... objective function:
#minimize capacity: sum{r in Resources} c[r] + 1E4*(sComp) + 1E4*sum{(j,s) in
#Jobs} sDelay[j,s] + 1E4*sum{(k,l) in Links, t in Time} sLinks[k,l,t];

minimize slowDown: sum{(j,s) in Jobs}((sum{r in Resources, t in (T0[j,s]+1)..(T-RunTime[j,s])} (t*x[j,s,r,t]) - T0[j,s] + RunTime[j,s])/RunTime[j,s]);
# ... constraints
subject to

   # ... defined variable y ... job cannot run before arriving
   #defineY{(j,s) in Jobs, r in Resources, t in (T0[j,s]+1)..(T-RunTime[j,s])}: 
          #y[j,s,r,t] = sum{tt in (T0[j,s]+1)..(T-RunTime[j,s]): tt>=t-RunTime[j,s]+1 && tt <=t} x[j,s,r,tt];

   # ... job cannot run before it is created
   #create{(j,s) in Jobs, r in Resources, t in Time: t <= T0[j,s]-1}: x[j,s,r,t] = 0;

   # ... every job is scheduled
   scheduled{(j,s) in Jobs}: sum{r in Resources, t in (T0[j,s]+1)..(T-RunTime[j,s])} x[j,s,r,t] = 1;

   # ... every job must finish (RunTime = sum y)
   #finish{(j,s) in Jobs}: sum{r in Resources, t in (T0[j,s]+1)..T} y[j,s,r,t] = RunTime[j,s];

   # ... compute capacity at every resource and all time points
   #computeCap{r in Resources, t in Time}: sum{(j,s) in Jobs:t >= (T0[j,s]+1)} 
   #NumNodes[j,s]*y[j,s,r,t] <= c[r];
   computeCap{r in Resources, t in Time}: sum{(j,s) in Jobs:t >= (T0[j,s]+1)} 
   NumNodes[j,s]*sum{tt in (T0[j,s]+1)..(T-RunTime[j,s]): tt>=t-RunTime[j,s]+1 && tt <=t} x[j,s,r,tt] <= c[r];

   # ... compute budget over all resources
   #computeBud: sum{r in Resources} c[r] - sComp <= ComputeBudget;
   computeBud: sum{r in Resources} c[r] <= ComputeBudget;

   # ...  data cannot arrive at the compute resource after the job has started
   finTrans{(j,s) in Jobs, r in Resources, t in (T0[j,s])..(T-RunTime[j,s]-1)}: 
   sum{p in 1..numPaths[s,r]} lambda[j,s,r,p,t] <= sum{tt in (T0[j,s]+1)..(T-RunTime[j,s]): tt >= t+1} x[j,s,r,tt]; 	#!!!

   # ...  data cannot be transmitted before a job is created
   #zeroLambdaT0{(j,s) in Jobs, r in Resources, p in 1..numPaths[s,r], t in Time: t <= T0[j,s]-1}: lambda[j,s,r,p,t] = 0;

   # ... capacity constraint on all links
   #linkCap1{t in Time, (k,l) in Links}:  
	#sum{(j,s) in Jobs, r in Resources, p in 1..numPaths[s,r]: (k,l) in Paths[s,r,p] && t >= T0[j,s] && t <= (T-RunTime[j,s])} 
		   #DataSize[j,s]*lambda[j,s,r,p,t] - sLinks[k,l,t] <= cap[k,l];
   linkCap1{t in Time, (k,l) in Links}:  
	sum{(j,s) in Jobs, r in Resources, p in 1..numPaths[s,r]: (k,l) in Paths[s,r,p] && t >= T0[j,s] && t <= (T-RunTime[j,s]-1)} 
		   DataSize[j,s]*lambda[j,s,r,p,t] <= cap[k,l];

   # ... can take only one path
   singlePath{(j,s) in Jobs, r in Resources}: sum{p in 1..numPaths[s,r]} z[j,s,r,p] = sum{t in (T0[j,s]+1)..(T-RunTime[j,s])} x[j,s,r,t];

   # ... can take only a valid path
   assignPath{(j,s) in Jobs, r in Resources, p in 1..numPaths[s,r]}: 
   sum{t in T0[j,s]..(T-RunTime[j,s]-1)} lambda[j,s,r,p,t] = z[j,s,r,p]; #!!!

   # ... upper bound on maximum delay for any job
   #uppDelay{(j,s) in Jobs}: 
   #sum{r in Resources, t in (T0[j,s]+1)..(T-RunTime[j,s])} ceil(TD[s,r] + t)*x[j,s,r,t] - sDelay[j,s]
   #<= floor(MaxDelayMult[j,s]*RunTime[j,s] - RunTime[j,s] + T0[j,s]);

   # ... Perc percentile of jobs within slowDown parameter
   percentile: sum {(j,s) in Jobs} w[j,s] >= ceil(card(Jobs)*Perc);

   # ... if w[j,s]=1 then job's delay within SlowDown
   slowDownPerc{(j,s) in Jobs}: 
   sum{r in Resources, t in (T0[j,s]+1)..(T-RunTime[j,s])} 
   x[j,s,r,t]*t - T0[j,s] <= RunTime[j,s]*( w[j,s]*SlowDown + M*(1 - w[j,s]) );
