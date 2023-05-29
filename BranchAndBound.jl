module BranchAndBound

using DataStructures
using DataFrames
using CSV

struct Node
    cost::Float64
    children::Vector{Node}
    partial_schedule::Vector{Int16}

end

function find_unscheduled(scheduled_nodes::Vector{Int16}, all_nodes::Vector{Int16})
    """
    Find unscheduled_nodes.
    """
    unscheduled_nodes = Vector{Int16}()
    for node in all_nodes
        if !(node in scheduled_nodes)
            pushfirst!(unscheduled_nodes, node)
        end
    end

    return unscheduled_nodes
end

function tardiness(scheduled_nodes::Vector{Int16}, processing_times::Vector{Float64}, due_dates::Vector{Int16}, all_nodes::Vector{Int16})
    """
    Compute the tardiness of scheduled nodes.
    """
    cost::Float64 = 0
    time::Float64 = 0
    unscheduled_nodes = find_unscheduled(scheduled_nodes, all_nodes)
    for node in unscheduled_nodes
        time = time + processing_times[node]
    end

    for node in scheduled_nodes
        time = time + processing_times[node]
        cost = cost + max(0, time - due_dates[node])
    end
    return cost
end


function get_node(node::Node, path::Vector{Int16})
    """
    Find a node from path.
    f a node has two children (eg 3,4), then name and indices differ
    """
    if length(path) == 0  # return root node
        return node
    end

    node_name = path[end]
    idx = -1
    for i in 1:length(node.children)
        if node.children[i].partial_schedule[1] == node_name
            idx = i
            break
        end
    end

    if length(path) == 1
        return node.children[idx]
    else
        return get_node(node.children[idx], path[1:end-1])
    end
end


function find_precedance_candidates(scheduled_nodes::Vector{Int16}, G::Matrix{Int16})
    """
    Find precedence candidates given a matrix G and a lit of already scheduled jobs
    """
    # add all nodes that have an edge from the scheduled nodes withuot scheduled nodes
    candidates = Set{Int16}()
    for node in scheduled_nodes
        potential_candidates = findall(>(0), G[:, node])
        filter!(x -> x ∉ scheduled_nodes, potential_candidates)
        deps = Set{Int16}()

        for p in potential_candidates
            deps = findall(>(0), G[p, :])
            if deps ⊆ scheduled_nodes
                union!(candidates, p)
            end
        end
    end
    return candidates
end


function estimate_heuristic_cost(partial_schedule::Vector{Int16}, all_nodes::Vector{Int16}, lower_bound::Float64)
    """
    Calculate the heuristic for estimating the tardiness lower bound
    """
    nodes_left = length(all_nodes) - length(partial_schedule)
    return lower_bound + nodes_left * (lower_bound / length(partial_schedule))
end


function complete_schedule(scheduled_nodes::Vector{Int16}, G::Matrix{Int16})
    """
    Complete an uncomplete schedule arbitrarly satisfying the precedence
    """
    while true
        candidates = find_precedance_candidates(scheduled_nodes, G)
        new_schedule = append!(collect(candidates), scheduled_nodes)
        length(candidates) != 0 || break
        scheduled_nodes = new_schedule
    end
    return scheduled_nodes
end

function complete_schedule_due_date(final_schedule::Vector{Int16}, G::Matrix{Int16}, due_dates, all_nodes)
    """
    Complete the schedule by soonest due date first
    """
    while length(final_schedule) < length(all_nodes)
        candidates = collect(find_precedance_candidates(final_schedule, G))
        candidate_due_dates = [due_dates[c] for c in candidates]
        idx = findall(x -> x == maximum(candidate_due_dates), candidate_due_dates)[1]
        pushfirst!(final_schedule, candidates[idx])
    end
    return final_schedule
end

function complete_schedule_hu(hue_schedule::Vector{Int16}, final_schedule::Vector{Int16})
    """
    Complete the partial schedule with the ordering given by hue schedule
    """
    for j in 1:length(hue_schedule)
        hue_node = hue_schedule[length(hue_schedule)-j+1]
        if hue_node ∉ final_schedule
            pushfirst!(final_schedule, hue_node)
        end
    end
    return final_schedule
end


function calcuate_hu_distance(G)
    """
    Calculate the hu distance(level) for each node
    """
    hue_distance = Dict()
    parents = [findmin(sum(G, dims=2))[2][1]]
    hue_distance[parents[1]] = 1
    while true
        next_parent = Set()

        for p in parents
            children = findall(>(0), G[:, p])
            union!(next_parent, children)
            for c in children
                hue_distance[c] = hue_distance[p] + 1
            end
        end

        parents = next_parent
        length(parents) != 0 || break
    end

    return hue_distance
end

function find_hu_schedule(G)
    """
    Schedule all nodes with the Hu's algorithm
    """
    hue_schedule = Vector{Int16}()
    hue_distance = calcuate_hu_distance(G)
    hue_keys = collect(keys(hue_distance))
    hue_vals = collect(values(hue_distance))

    while length(hue_schedule) < length(G[:, 1])
        min_val = findmin(hue_vals)[1]

        node = maximum(hue_keys[findall(x -> x == min_val, hue_vals)])
        idx = findall(x -> x == node, hue_keys)[1]

        pushfirst!(hue_schedule, node)
        deleteat!(hue_keys, idx)
        deleteat!(hue_vals, idx)
    end
    return hue_schedule
end


function finish_partial_schedule(costs, due_dates, all_nodes, G)
    """
    Finish an uncomplete schedule generated by a branch and bound algorithm
    """
    ## Find longest length, min cost schedule 
    cost_keys = collect(keys(costs))
    cost_values = collect(values(costs))
    longest_schedule = findmax(map(length, cost_keys))[1]
    indices = findall(x -> length(x) == longest_schedule, cost_keys)
    min_cost = minimum(cost_values[indices])
    idx = findall(x -> length(x) == longest_schedule && costs[x] == min_cost, cost_keys)[1]
    longest_schedule = cost_keys[idx]
    final_schedule = longest_schedule

    ### Finish via hue schedule
    # println("Completing partial schedule via hu's:", final_schedule)
    # hue_schedule = find_hu_schedule(G)
    # final_schedule = complete_schedule_hu(hue_schedule, final_schedule)

    ### Finish by soonest due date first
    println()
    println("Completing partial schedule via due date: ", final_schedule)
    println()
    final_schedule = complete_schedule_due_date(final_schedule, G, due_dates, all_nodes)

    ### Finish arbitrarly
    # println("Completing partial schedule arbitrarly", final_schedule)
    # final_schedule = complete_schedule(final_schedule, G)

    return final_schedule
end


# ---------------- VANILLA BRANCH AND BOUND ----------------
function question2_branch_and_bound(G::Matrix{Int16}, processing_times::Vector{Float64}, due_dates::Vector{Int16}, all_nodes::Vector{Int16}; max_iter=30000, log=false)
    """
    Vanilla Branch and Bounf for question 2
    """
    t0 = time()

    costs = PriorityQueue{Vector{Int16},Float64}(Base.Order.Forward)
    final_schedule = []#Vector{Int16}()

    counter::Int32 = 0
    num_pending::Int32 = 0
    num_complete_solutions::Int32 = 0
    keep_branching::Bool = true
    best_bound::Float64 = 100000
    best_bound_schedule = []

    # Initialise root node with potential nodes (in this case, all children since no precedence)
    root_schedule = Vector{Int16}([findmin(sum(G, dims=2))[2][1]])
    root_node = Node(tardiness(root_schedule, processing_times, due_dates, all_nodes), [], root_schedule)

    enqueue!(costs, root_node.partial_schedule, root_node.cost)

    while keep_branching && counter < max_iter
        counter += 1

        new_parent_path = dequeue!(costs)
        parent_node = get_node(root_node, new_parent_path[1:end-1])

        # LOG PRINT OUT
        if log
            print(" Iter: ", counter)
            print(" Partial Schedule: ", parent_node.partial_schedule)
            print(" Cost: ", parent_node.cost)
            println()
        end

        # if we pop a full schedule, it must be optimal
        if length(parent_node.partial_schedule) == length(all_nodes)
            keep_branching = false
            final_schedule = parent_node.partial_schedule
            break
        end
        # If we pop a schedule with same cost as best bound, no need to continue
        # this handles case where a complete schedule has same cost as a partial schedule
        if parent_node.cost >= best_bound
            final_schedule = best_bound_schedule
            keep_branching = false
            break
        end

        num_pending = max(num_pending, length(costs))

        # First 2 and last 2 iterations print statements
        if (counter < 3 || counter > max_iter - 2)
            println("Iteration: $(counter), node: $(parent_node.partial_schedule), lower tardiness bound $(parent_node.cost)")
        end

        candidates = find_precedance_candidates(parent_node.partial_schedule, G)

        # Loop over candidates - create children
        for node in candidates
            partial_schedule = copy(parent_node.partial_schedule)
            pushfirst!(partial_schedule, node)

            cost = tardiness(partial_schedule, processing_times, due_dates, all_nodes)

            if length(partial_schedule) == length(all_nodes)
                num_complete_solutions += 1
                # If child is complete schedule, check if we can improve lower bound
                if cost < best_bound
                    best_bound_schedule = partial_schedule
                    best_bound = cost
                end
            end

            # Rounding the lower bound 
            child = Node(round(cost; digits=8), [], partial_schedule)

            enqueue!(costs, child.partial_schedule, child.cost)

            # Update parent's children, costs
            push!(parent_node.children, child)
        end

    end

    # Complete incomplete schedule
    if keep_branching
        final_schedule = finish_partial_schedule(costs, due_dates, all_nodes, G)
    end

    final_cost = tardiness(final_schedule, processing_times, due_dates, all_nodes)

    println("Completed $(counter) iterations in $(round(time() - t0, digits=1)) seconds, $(num_complete_solutions) complete schedules. Final cost: $(final_cost)")
    println("Final schedule: ", final_schedule)
    println("Max pending nodes: ", num_pending)
    return final_schedule, final_cost
end



# ---------------- DEPTH FIRST SEARCH ----------------
function depth_first_search(G::Matrix{Int16}, processing_times::Vector{Float64}, due_dates::Vector{Int16}, all_nodes::Vector{Int16}; max_iter=30000, log=false)
    """
    Depth First Search approach implemented with a PriorityQueue 
    that keeps the longest schedules at the front.
    """
    t0 = time()

    distances = PriorityQueue{Vector{Int16},Int64}(Base.Order.Forward)

    final_schedule = []#Vector{Int16}()

    counter::Int32 = 0
    num_pending::Int32 = 0
    num_complete_solutions::Int32 = 0
    keep_branching::Bool = true
    best_bound::Float64 = 100000 # best solution seen so far
    best_bound_schedule = []

    root_schedule = Vector{Int16}([findmin(sum(G, dims=2))[2][1]])
    root_node = Node(tardiness(root_schedule, processing_times, due_dates, all_nodes), [], root_schedule)

    enqueue!(distances, root_node.partial_schedule, length(all_nodes) - length(root_node.partial_schedule))

    while keep_branching && counter < max_iter && !isempty(distances)
        counter += 1

        new_parent_path = dequeue!(distances)
        parent_node = get_node(root_node, new_parent_path[1:end-1])

        if log
            print(" Iter: ", counter)
            print(" Partial Schedule: ", parent_node.partial_schedule)
            print(" Cost: ", parent_node.cost)
            println()
        end

        # Solution found
        if length(parent_node.partial_schedule) == length(all_nodes)
            num_complete_solutions += 1
            if parent_node.cost < best_bound
                best_bound = parent_node.cost
                best_bound_schedule = parent_node.partial_schedule
            end
        end
        num_pending = max(num_pending, length(distances))

        candidates = find_precedance_candidates(parent_node.partial_schedule, G)

        # Loop over candidates - create children
        for node in candidates
            partial_schedule = copy(parent_node.partial_schedule)
            pushfirst!(partial_schedule, node)
            cost = tardiness(partial_schedule, processing_times, due_dates, all_nodes)

            # Only add children that have lower bound than the best bound
            if cost < best_bound
                child = Node(round(cost; digits=8), [], partial_schedule)
                enqueue!(distances, child.partial_schedule, length(all_nodes) - length(child.partial_schedule))
                push!(parent_node.children, child)
            end
        end
    end

    # Complete incomplete schedule
    if keep_branching && length(best_bound_schedule) != length(all_nodes)
        final_schedule = finish_partial_schedule(distances, due_dates, all_nodes, G)
    else
        final_schedule = best_bound_schedule
    end

    final_cost = tardiness(final_schedule, processing_times, due_dates, all_nodes)

    println("Completed $(counter) iterations in $(round(time() - t0, digits=1)) seconds, $(num_complete_solutions) complete schedules. Final cost: $(final_cost)")
    println("Final schedule: ", final_schedule)
    println("Max pending nodes: ", num_pending)

    return final_schedule, final_cost
end





# ---------------- PROJECTED COST HEURISTIC ----------------
function branch_and_bound_projected_cost(G::Matrix{Int16}, processing_times::Vector{Float64}, due_dates::Vector{Int16}, all_nodes::Vector{Int16}; max_iter=30000, log=false)
    t0 = time()

    cost_estimates = PriorityQueue{Vector{Int16},Float64}(Base.Order.Forward)

    final_schedule = []#Vector{Int16}()

    counter::Int32 = 0
    num_pending::Int32 = 0
    num_complete_solutions::Int32 = 0
    keep_branching::Bool = true
    best_bound::Float64 = 100000
    best_bound_schedule = []

    root_schedule = Vector{Int16}([findmin(sum(G, dims=2))[2][1]])
    root_cost = tardiness(root_schedule, processing_times, due_dates, all_nodes)
    root_node = Node(root_cost, [], root_schedule)

    enqueue!(cost_estimates, root_node.partial_schedule, estimate_heuristic_cost(root_node.partial_schedule, all_nodes, root_node.cost))

    while keep_branching && counter < max_iter && !isempty(cost_estimates)
        counter += 1
        new_parent_path = dequeue!(cost_estimates)
        parent_node = get_node(root_node, new_parent_path[1:end-1])

        if log
            print(" Iter: ", counter)
            print(" Partial Schedule: ", parent_node.partial_schedule)
            print(" Cost: ", parent_node.cost)
            println()
        end

        # Solution found
        if length(parent_node.partial_schedule) == length(all_nodes)
            num_complete_solutions += 1
            if parent_node.cost < best_bound
                best_bound = parent_node.cost
                best_bound_schedule = parent_node.partial_schedule
            end
        end
        num_pending = max(num_pending, length(cost_estimates))

        candidates = find_precedance_candidates(parent_node.partial_schedule, G)

        # Loop over candidates - create children
        for node in candidates
            partial_schedule = copy(parent_node.partial_schedule)
            pushfirst!(partial_schedule, node)
            cost = tardiness(partial_schedule, processing_times, due_dates, all_nodes)

            # Only add children that have lower cost than the best bound
            if cost < best_bound
                child = Node(round(cost; digits=8), [], partial_schedule)
                enqueue!(cost_estimates, child.partial_schedule, estimate_heuristic_cost(child.partial_schedule, all_nodes, child.cost))
                push!(parent_node.children, child)
            end
        end
    end

    # Complete incomplete schedule
    if keep_branching && length(best_bound_schedule) != length(all_nodes)
        # This will give errors -> the costs pq
        final_schedule = finish_partial_schedule(cost_estimates, due_dates, all_nodes, G)
    else
        final_schedule = best_bound_schedule
    end

    final_cost = tardiness(final_schedule, processing_times, due_dates, all_nodes)

    println("Completed $(counter) iterations in $(round(time() - t0, digits=1)) seconds, $(num_complete_solutions) complete schedules. Final cost: $(final_cost)")
    println("Final schedule: ", final_schedule)
    println("Max pending nodes: ", num_pending)
    return final_schedule, final_cost
end


# ---------------- DOMINANCE ----------------
function branch_and_bound_dominance(G::Matrix{Int16}, processing_times::Vector{Float64}, due_dates::Vector{Int16},
    all_nodes::Vector{Int16}; max_iter=30000, log=false)
    """
    Branch and Bound algorithm with an additional dominance check for fathoming nodes
    """
    t0 = time()

    costs = PriorityQueue{Vector{Int16},Float64}(Base.Order.Forward)
    final_schedule = Vector{Int16}()

    # same as costs except we never dequeue
    historical_costs = PriorityQueue{Vector{Int16},Float64}(Base.Order.Forward)

    counter::Int32 = 0
    num_pending::Int32 = 0
    num_dominated::Int32 = 0
    num_complete_solutions::Int32 = 0
    keep_branching::Bool = true
    best_bound::Float64 = 1000000
    best_bound_schedule = []

    # Initialise root node with potential nodes (in this case, all children since no precedence)
    root_schedule = Vector{Int16}([findmin(sum(G, dims=2))[2][1]])
    root_node = Node(tardiness(root_schedule, processing_times, due_dates, all_nodes), [], root_schedule)

    enqueue!(costs, root_node.partial_schedule, root_node.cost)

    while keep_branching && counter < max_iter

        ### Check Dominanace
        if counter > 0
            while true
                new_parent_schedule, new_parent_cost = peek(costs)
                dequeue!(costs)
                dominated = false
                for (schedule, cost) in historical_costs
                    if length(new_parent_schedule) <= length(schedule) && new_parent_cost > cost && new_parent_schedule ⊆ schedule
                        dominated = true
                        num_dominated += 1

                        ### To see dominance taking place
                        # println("-----------------------------")
                        # println("cost=$(new_parent_cost)   ", new_parent_schedule)
                        # println("dominated by")
                        # println("cost=$(cost)   ", schedule)
                        # extra = collect(setdiff(Set(schedule), Set(new_parent_schedule)))
                        # println("extra jobs done:  ", extra)
                        break
                    end
                end
                if !(dominated)
                    break
                end
            end
        else
            new_parent_schedule = dequeue!(costs)
        end
        parent_node = get_node(root_node, new_parent_schedule[1:end-1])

        counter += 1

        if log
            print(" Iter: ", counter)
            print(" Partial Schedule: ", parent_node.partial_schedule)
            print(" Cost: ", parent_node.cost)
            println()
        end

        num_pending = max(num_pending, length(costs))

        # if we pop a full schedule, it must be optimal
        if length(parent_node.partial_schedule) == length(all_nodes)
            final_schedule = parent_node.partial_schedule
            keep_branching = false
            break
        end
        # If we pop a schedule with same cost as best bound, no need to continue
        # this handles case where a complete schedule has same cost as a partial schedule
        if parent_node.cost >= best_bound
            final_schedule = best_bound_schedule
            keep_branching = false
            break
        end

        candidates = find_precedance_candidates(parent_node.partial_schedule, G)

        # Loop over candidates - create children
        for node in candidates
            partial_schedule = copy(parent_node.partial_schedule)
            pushfirst!(partial_schedule, node)

            cost = tardiness(partial_schedule, processing_times, due_dates, all_nodes)

            if length(partial_schedule) == length(all_nodes)
                num_complete_solutions += 1
                # If child is complete schedule, check if we can improve lower bound
                if cost < best_bound
                    best_bound_schedule = partial_schedule
                    best_bound = cost
                end
            end

            # Rounding the lower bound to prevent fake domination
            child = Node(round(cost; digits=8), [], partial_schedule)
            enqueue!(costs, child.partial_schedule, child.cost)
            enqueue!(historical_costs, child.partial_schedule, child.cost)
            # Update parent's children, costs
            push!(parent_node.children, child)
        end
    end

    if keep_branching
        final_schedule = finish_partial_schedule(costs, due_dates, all_nodes, G)
    end

    final_cost = tardiness(final_schedule, processing_times, due_dates, all_nodes)

    println("Completed $(counter) iterations in $(round(time() - t0, digits=1)) seconds, $(num_complete_solutions) complete schedules. Final cost: $(final_cost)")
    println("Final schedule: ", final_schedule)
    println("Max pending nodes: ", num_pending)

    return final_schedule, final_cost
end

end