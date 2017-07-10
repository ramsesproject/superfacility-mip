# eSciencePath.ampl - AMPL run file: type ampl eSciencePath.ampl
# 
# Created by Sven Leyffer, Argonne National Laboratory, June 2017
##################################################################

model eSciencePercentile.mod;            # ... model file (equations)
data  eSciencePercentile.dat; 		       # ... data file (instance)

#provide good initial solution
for {(j,s) in Jobs} {
  if (s="APS") then {
    let z[j,s,"ANL",1] :=1; # single path
    let x[j,s,"ANL",T0[j,s]+1] :=1; # assign when generated + 1
    let lambda[j,s,"ANL",1,T0[j,s]] :=1; # data arrives when generated
  }
  else if (s="ALS") then {
    let z[j,s,"NERSC",1] :=1;
    let x[j,s,"NERSC",T0[j,s]+1] :=1; # assign when generated + 1
    let lambda[j,s,"NERSC",1,T0[j,s]] :=1; # data arrives when generated
  }
  else if (s="SSRL") then {
    let z[j,s,"NERSC",1] :=1;
    let x[j,s,"NERSC",T0[j,s]+1] :=1; # assign when generated + 1
    let lambda[j,s,"NERSC",1,T0[j,s]] :=1; # data arrives when generated
  }
  else if (s="ALS") then {
    let z[j,s,"ORNL",1] :=1;
    let x[j,s,"ORNL",T0[j,s]+1] :=1; # assign when generated + 1
    let lambda[j,s,"ORNL",1,T0[j,s]] :=1; # data arrives when generated
  }
}
option solver cplex;                # ... define solver & options
#option cplex_options "mipdisplay=2 mipinterval=1000 mipgap=0.01 time=86400";
option cplex_options "mipdisplay=2 mipinterval=1000 mipgap=0.03 time=864000 poolstub=Percentile poolcapacity=50";
solve;                            # ... solve the model/data

#for {k in 1.._ncons} {
 #if _con[k].slack > -1E-5 then { 
  #display _conname, _con.slack;
 #}
#}
#display scheduled[11,'ALS'], scheduled[12,'SSRL'], scheduled[17,'SSRL'], scheduled[49,'APS'], scheduled[29,'APS'];
#expand;

#display sComp;
#display {(j,s) in Jobs:sDelay[j,s]>0} sDelay[j,s];
display c;
#display {t in Time, (k,l) in Links:sLinks[k,l,t]>0} sLinks[k,l,t];
display {(j,s) in Jobs, r in Resources, t in (T0[j,s]+1)..(T-RunTime[j,s]): x[j,s,r,t] >= 0.5} x[j,s,r,t];

for {i in 1..Current.npool}
{
  solution ("Percentile" & i & ".sol");
  display c;
}

exit;

display {(k,l) in Links:cap[k,l]>1E-5} cap[k,l];
display {(j,s) in Jobs, r in Resources, p in 1..numPaths[s,r]:z[j,s,r,p]>0.5} z[j,s,r,p];
display {(j,s) in Jobs, r in Resources, t in Time: x[j,s,r,t]>0.5} x[j,s,r,t];
display {(j,s) in Jobs, r in Resources, p in 1..numPaths[s,r], t in Time: lambda[j,s,r,p,t]==1} lambda[j,s,r,p,t];
