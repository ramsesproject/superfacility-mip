# Introduction

A mixed integer programming model to solve design choices of super facility. The model is implemented by using AMPL, we have tried to use CPLEX to solve it

# Module description 

| File   | Description  |
|:-----|:-----|
| superFacility.mod | Model implementation |
| superFacility.dat | COnfiguration file for parameters, e.g., network, hpc site, science site|
| superFacility.ampl | main entrance, result display |


# Tutorial 

## Requirement 

* AMPL with CPLEX solver. you can request a free 30-day full trial at http://ampl.com/try-ampl/request-a-full-trial/. It has cplex solver as well.

* Computing node with ~1024 GB memory (or use virtual memory or reduce the number of thread to use, but either one will be slow)

## Run

ampl eSciencePercentile.ampl
