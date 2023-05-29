include("Constants.jl")
include("BranchAndBound.jl")

import .Constants
import .BranchAndBound
using DataFrames
using CSV
println("Using $(Threads.nthreads()) threads")
println()


# Constants provided in the report or taken from Azuere
processing_times_q2 = Constants.processing_times_q2
processing_times_q3 = Constants.processing_times_q3
G = Constants.G
due_dates = Constants.due_dates
all_nodes = Constants.all_nodes


# Change to true to see each iteration print outs.
show_log = false

# ######## Question 2 ########

println("Running all BnB methods for 30k iterations\n")

# Vanilla Branch and Bound
println("----------- Vanilla Branch and Bound -----------\n")
BranchAndBound.question2_branch_and_bound(G, processing_times_q2, due_dates, all_nodes; max_iter=30000, log=show_log)
println()

# HU's algorithm
println("----------- HU's Algorithm -----------\n")
hu_schedule = Vector{Int16}(BranchAndBound.find_hu_schedule(G))
hu_cost = BranchAndBound.tardiness(hu_schedule, processing_times_q2, due_dates, all_nodes)
println("Hu schedule cost: ", hu_cost)
println("Hu schedule: ", hu_schedule)
println()


######## Question 3 ########

# Depth-First Search
println("----------- Depth-First Search -----------\n")
BranchAndBound.depth_first_search(G, processing_times_q3, due_dates, all_nodes; max_iter=30000, log=show_log)
println()

# Projected Cost
println("----------- Projected Cost -----------\n")
BranchAndBound.branch_and_bound_projected_cost(G, processing_times_q3, due_dates, all_nodes; max_iter=30000, log=show_log)
println()

# Dominance Branch and Bound
println("----------- Dominance Branch and Bound -----------\n")
BranchAndBound.branch_and_bound_dominance(G, processing_times_q3, due_dates, all_nodes; max_iter=30000, log=show_log);
println()

