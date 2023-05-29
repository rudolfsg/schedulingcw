# Scheduling coursework

A branch-and-bound solver which finds the optimal schedule for a set of nodes with precedence relations (i.e. a directed acyclic graph). It minimises the (total tardiness)[https://en.wikipedia.org/wiki/Tardiness_(scheduling)] of the schedule which depends on the processing time, due date and scheduled order of each node. 

Joint coursework with Jan Marczak.


## Instructions

The solver is written in Julia - install it from here https://julialang.org

Then install relevant packages:

`import Pkg; Pkg.add("DataStructures"); Pkg.add("CSV"); Pkg.add("DataFrames")`

Finally run the following command: `julia run_experiment.jl`