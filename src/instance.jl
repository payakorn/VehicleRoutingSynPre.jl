struct Ins
    name::String
    num_node::Int64
    num_vehi::Int64
    num_serv::Int64
    serv_a::Tuple
    serv_r::Dict
    mind::Vector{Float64}
    maxd::Vector{Float64}
    a::Array{Int64}
    r::Array{Int64}
    d::Matrix{Float64}
    p::Array{Float64}
    e::Vector{Int64}
    l::Vector{Int64}
    PRE::Vector{Tuple}
    SYN::Vector{Tuple}
end


mutable struct Sol
    route::Array
    slot::Dict
    ins::Ins
end

"""
---
use to load all data from instance including 

number of node, vehicle service, ...

---

## `Example:`

```julia
ins = load_ins("ins10-1")
```
"""
function load_ins(Name::String)
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(Name)

    # find Synchronization and Precedence constraints
    serv_r = find_service_request(r)
    serv_a = find_compat_vehicle_node(a, r)
    SYN = find_SYN(serv_r, mind, maxd)
    PRE = find_PRE(serv_r, mind, maxd)
    return Ins(Name, num_node, num_vehi, num_serv, serv_a, serv_r, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end

"""
```julia
    sortperm(ins::Ins)
```

---

Example:

```julia
    ins = load_ins("ins10-1")
    sl = sortperm(ins)
```

use to sort the upper time window of instance

"""
function sortperm_l(ins::Ins)
    setdiff(Base.sortperm(ins.l), [1, length(ins.l)])
end

"""
```julia
    all_node_serv(ins::Ins)
```

find all node and service needed to schedule in the from

Vector[[node, service]]
[[1, 1], [10, 2], [5, 3], ...]

---

`Example:`

```
    ins = load_ins("ins10-1")
    all_ns = all_node_serv(ins)
```
"""
function all_node_serv(ins::Ins)
    all_ns = Vector{Int64}[]
    push!(all_ns, [1, 1])
    for i in 2:ins.num_node
        for j in findall(x->x==1, ins.r[i, :])
            push!(all_ns, [i, j])
        end
    end
    # findall(BitMatrix(ins.r))
    return all_ns
end


"""
```julia
    generate_empty_sol(ins::Ins)
```

---

use to generate empty solution of instance; the route = [[[1, 1]], 
                                                        [[1, 1]],
                                                         .
                                                         .
                                                         .
                                                         [[1, 1]]]

---

Example:

```julia
    ins = load_ins("ins10-1")
    sol = generate_empty_sol(ins)
```
"""
function generate_empty_sol(ins::Ins)
    route = [[[1, 1]] for _ in 1:ins.num_vehi]
    slot = Dict{Int64, Vector{Int64}}()
    for syn in ins.SYN
        slot[syn[1]] = Int64[syn[2], syn[3]]
    end
    
    for pre in ins.PRE
        slot[pre[1]] = Int64[pre[2], pre[3]]
    end
    return Sol(route, slot, ins)
end


function generate_particles(ins::Ins)
    sol = generate_empty_sol(ins)
    sol = insert_node_service(sol)
    return sol
end


function inserted_node(sol::Sol)
    an = all_node_serv(sol.ins)
    all_node = Vector{Int64}[]
    for i in 1:sol.ins.num_vehi
        append!(all_node, sol.route[i])
    end

    setdiff!(an, all_node)

    return an
end


function load_example1()
    route, slot = example()
    ins = load_ins("ins10-1")
    sol = generate_empty_sol(ins)
    sol.route = route
    return sol
end


function swap(sol::Sol, list)
    input_route = deepcopy(sol.route)
    for ls in list
        num_v1, num_loca1 = find_location_by_node_service(input_route, ls[1][1], ls[1][2])
        num_v2, num_loca2 = find_location_by_node_service(input_route, ls[2][1], ls[2][2])
        test_route = deepcopy(input_route)
        test_route[num_v1][num_loca1], test_route[num_v2][num_loca2] = test_route[num_v2][num_loca2], test_route[num_v1][num_loca1]
        if compatibility(test_route, sol.slot, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.PRE, sol.ins.SYN) 
            # test_st = starttime(test_route, slot, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
            # st = starttime(route, slot, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
            test_st = try starttime(sol, test_route) catch StackOverflowError; continue end
            st = try starttime(sol, input_route) catch StackOverflowError; continue end 
            if objective_value(test_route, test_st, sol.ins.p, sol.ins.l, sol.ins.d) < objective_value(input_route, st, sol.ins.p, sol.ins.l, sol.ins.d) && check_PRE(test_route, test_st, sol.ins.maxd, sol.ins.PRE) && check_SYN(test_route, sol.ins.SYN)
                input_route = deepcopy(test_route)
            end
        end
    end
    sol.route = input_route
    return sol
end


function move(sol::Sol, list)
    input_route = deepcopy(sol.route)
    for ls in list
        num_v1, num_loca1 = find_location_by_node_service(input_route, ls[1][1], ls[1][2])
        num_v2, num_loca2 = find_location_by_node_service(input_route, ls[2][1], ls[2][2])
        test_route = deepcopy(input_route)

        #  move
        moved_item = splice!(test_route[num_v1], num_loca1)
        insert!(test_route[num_v2], num_loca2, moved_item)

        # find starttime
        test_st = try starttime(sol, test_route) catch StackOverflowError; continue end
        st = starttime(sol, input_route)

        if compatibility(test_route, sol.slot, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.PRE, sol.ins.SYN) && objective_value(test_route, test_st, sol.ins.p, sol.ins.l, sol.ins.d) < objective_value(input_route, st, sol.ins.p, sol.ins.l, sol.ins.d) && check_PRE(test_route, test_st, sol.ins.maxd, sol.ins.PRE) && check_SYN(test_route, sol.ins.SYN)
            # println("cost reduce in Move")
            input_route = deepcopy(test_route)
        end
    end
    sol.route = input_route
    return sol
end


function local_search(particle::Sol, best_par::Sol)
    test_par = deepcopy(particle)
    list = List(particle.ins.num_node, particle.ins.num_vehi, particle.ins.num_serv, particle.ins.r, particle.ins.SYN, particle.ins.PRE)
    # first_obj = objective_value(test_par)
    test_par = swap(test_par, list)
    test_par = move(test_par, list)
    # test_par = path_relinking(test_par, best_par)
    return test_par
end


function total_distance(sol::Sol)
    return total_distance(sol.route, sol.ins.d)
end


function tardiness(sol::Sol)
    return tardiness(sol.route, starttime(sol), sol.ins.p, sol.ins.l)
end


function objective_value(sol::Sol)
    return objective_value(sol.route, starttime(sol), sol.ins.p, sol.ins.l, sol.ins.d)
end


function find_starttime(sol::Sol)
    # st = initial_starttime(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv)
    find_starttime(sol.route, sol.slot, sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.mind, sol.ins.maxd, sol.ins.a, sol.ins.r, sol.ins.d, sol.ins.p, sol.ins.e, sol.ins.l, sol.ins.PRE, sol.ins.SYN)
end


function insert_node_sevice(sol::Sol, node::Int64, serv::Int64)
    nothing
end


function find_before_after_serv(ins::Ins, node::Int64)
    if any(in.(node, [ins.PRE[i][1] for i in 1:length(ins.PRE)]))
        index_pre = findfirst(in.(node, [ins.PRE[i][1] for i in 1:length(ins.PRE)]))
        return ins.PRE[index_pre][2:3]
    elseif any(in.(node, [ins.SYN[i][1] for i in 1:length(ins.SYN)]))
        index_syn = findfirst(in.(node, [ins.SYN[i][1] for i in 1:length(ins.SYN)]))
        return ins.SYN[index_syn][2:3]
    end
    throw("find_before_after_serv => Not found node $node in PRE or SYN")
end

"""
```julia
    insert_node_service(test_sol::Sol)
```

---

use to insert all node service to route in sol

"""
function insert_node_service(test_sol::Sol)
    sol = deepcopy(test_sol)
    remain_node = inserted_node(sol)
    sorted_node = sortperm_l(sol.ins)
    for node in sorted_node
        if any(in.(node, remain_node))
            com_serv = findall(x->x==1, sol.ins.r[node, :])
            if length(com_serv) == 1
                compat_vehicle = rand(findall(x->x==1, sol.ins.a[:, com_serv]))
                insert!(sol.route[compat_vehicle], length(sol.route[compat_vehicle]), [node, com_serv[1]])
                # println("node: $node, has 1 service")
            else
                # println("node: $node, has 2 services")
                serv_all = [i for i in find_before_after_serv(sol.ins, node)]

                com_vehi1 = findall(x->x==1, sol.ins.a[:, serv_all[1]])
                com_vehi2 = findall(x->x==1, sol.ins.a[:, serv_all[2]])
                if isempty(intersect(com_vehi1, com_vehi2))
                    com_vehi = [rand(com_vehi1), rand(com_vehi2)]
                elseif isempty(setdiff(com_vehi1, com_vehi2))
                    com2 = rand(com_vehi2)
                    com1 = rand(setdiff(com_vehi2, com2))
                    com_vehi = [com1, com2]
                elseif isempty(setdiff(com_vehi1, com_vehi2))
                    com1 = rand(com_vehi1)
                    com2 = rand(setdiff(com_vehi1, com1))
                    com_vehi = [com1, com2]
                end

                # insert 2 services
                insert!(sol.route[com_vehi[1]], length(sol.route[com_vehi[1]]), [node, serv_all[1]])
                insert!(sol.route[com_vehi[2]], length(sol.route[com_vehi[2]]), [node, serv_all[2]])
            end
        end
    end
    return sol
end


function swap(sol::Sol)
    list = List(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.r, sol.ins.SYN, sol.ins.PRE)
    sol.route = swap(sol.route, sol.slot, sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.mind, sol.ins.maxd, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.d, sol.ins.p, sol.ins.e, sol.ins.l, sol.ins.PRE, sol.ins.SYN, list)
    return sol
end


function List(sol::Sol)
    list = List(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.r, sol.ins.SYN, sol.ins.PRE)
end


# function swap(sol::Sol, list)
#     sol.route = swap(sol.route, sol.slot, sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.mind, sol.ins.maxd, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.d, sol.ins.p, sol.ins.e, sol.ins.l, sol.ins.PRE, sol.ins.SYN, list)
#     return sol
# end


function move(sol::Sol)
    list = List(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.r, sol.ins.SYN, sol.ins.PRE)
    sol.route = move(sol.route, sol.slot, sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.mind, sol.ins.maxd, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.d, sol.ins.p, sol.ins.e, sol.ins.l, sol.ins.PRE, sol.ins.SYN, list)
    return sol
end


function random_move(sol::Sol)
    list = List(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.r, sol.ins.SYN, sol.ins.PRE)
    sol.route = random_move(sol.route, sol.slot, sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.mind, sol.ins.maxd, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.d, sol.ins.p, sol.ins.e, sol.ins.l, sol.ins.PRE, sol.ins.SYN, list)
    return sol
end


function path_relinking(route::Array, best_route::Array, a)
    test_route = deepcopy(route)

    rand_vehi = rand(1:length(route))
    remove_route = test_route[rand_vehi]
    remove_best_route = best_route[rand_vehi]
    
    remain_node = setdiff(remove_route, remove_best_route)

    # insert best route
    test_route[rand_vehi] = best_route[rand_vehi]

    # insert
    for ns in remain_node
        choose_vehi = rand(findall(x->x==1, a[:, ns[2]]))
        choose_posi = length(test_route[choose_vehi])
        insert!(test_route[choose_vehi], choose_posi, ns)
    end
    return test_route
end


function path_relinking(par::Sol, par_best::Sol)
    # best_route = rand(par_best.route)
    route = path_relinking(par.route, par_best.route, par.ins.a)
    par.route = route
    return par
end


function initial_starttime(sol::Sol)
    initial_starttime(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv)
end


function find_other_serv_in_syn_pre(node, serv, SET; is_pre=false)
    pre = SET[findfirst(x->x[1]==node, SET)]
    other_serv = setdiff(pre, [node, serv])[1]
    if is_pre
        if findfirst(pre[2:end] .== serv) < findfirst(pre[2:end] .== other_serv)
            return other_serv, false
        else
            return other_serv, true
        end
    else
        return other_serv
    end
end


function check_SYN(sol::Sol)
    check_SYN(sol.route, sol.ins.SYN)
end


function check_PRE(sol::Sol)
    check_PRE(sol.route ,starttime(sol), sol.ins.maxd, sol.ins.PRE)
end


function compatibility(sol::Sol)
    compatibility(sol.route, sol.slot, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.PRE, sol.ins.SYN)
end


function forward_starttime(sol::Sol, st::Dict, start_lo::Int64, stop_lo::Int64, vehi::Int64)
    min_end = minimum([stop_lo, length(sol.route[vehi])])
    for lo in start_lo+1:min_end

        # last node and service
        bnode = sol.route[vehi][lo-1][1]
        bserv = sol.route[vehi][lo-1][2]

        # current node and service
        node = sol.route[vehi][lo][1]
        serv = sol.route[vehi][lo][2]

        arrival_time = st[bnode][vehi, bserv] + sol.ins.p[vehi, bserv, bnode] + sol.ins.d[bnode, node]

        if arrival_time < sol.ins.e[node] # when starttime is not change
            return st
        elseif in_SYN(node, sol.ins.SYN)
            st[node][vehi, serv] = arrival_time
            other_serv = find_other_serv_in_syn_pre(node, serv, sol.ins.SYN)
            ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)
            st = forward_starttime(sol, st, oloca, lo, ovehi)
        elseif in_PRE(node, sol.ins.PRE)
            st[node][vehi, serv] = arrival_time
            other_serv, before_serv = find_other_serv_in_syn_pre(node, serv, sol.ins.PRE, is_pre=true)
            ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)
            
            if before_serv
                if st[node][vehi, serv] - st[node][ovehi, other_serv] > sol.ins.maxd[node]
                    st[node][ovehi, other_serv] = st[node][vehi, serv] - sol.ins.maxd[node]
                    st = forward_starttime(sol, st, oloca, lo, ovehi)
                end
            else
                if st[node][ovehi, other_serv] - st[node][vehi, serv] < sol.ins.mind[node]
                    st[node][ovehi, other_serv] = sol.ins.mind[node] + st[node][vehi, serv]
                    st = forward_starttime(sol, st, oloca, lo, ovehi)
                end
            end
        else
            st[node][vehi, serv] = arrival_time
        end
    end
    return st
end


function find_starttime(route, slot, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
    st = initial_starttime(num_node, num_vehi, num_serv)

    # find max column
    len_route = [length(route[i]) for i in 1:num_vehi]
    maxcolumn = maximum(len_route)

    calculated = Int64[]

    for column in 1:maxcolumn
        for v in 1:num_vehi
            if column <= len_route[v]

                # find departure and arrival node
                if column == 1
                    bnode = 1
                    bserv = 1
                else
                    bnode = route[v][column-1][1]
                    bserv = route[v][column-1][2]
                end
                node = route[v][column][1]
                serv = route[v][column][2]
                
                min_st = st[bnode][v, bserv] + d[bnode, node] + p[v, bserv, bnode]
                if min_st < e[node]
                    min_st = e[node]
                end


                println("calculate column $column vehicle $v node $(route[v][column])")
                println("e = $(e[node]), d = $(d[bnode, node]) arrive time = $(st[bnode][v, bserv] + d[bnode, node] + p[v, bserv, bnode])")

                if in_SYN(node, SYN) && in(node, calculated)
                    # find location of syn node
                    other_serv = find_other_serv_in_syn_pre(node, serv, SYN)
                    ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)
                    if min_st < st[node][ovehi, other_serv]
                        # println("update min_st")
                        st[node][v, serv] = st[node][ovehi, other_serv]
                    elseif min_st > st[node][ovehi, other_serv]
                        st[node][v, serv] = min_st
                        st[node][ovehi, other_serv] = min_st
                        st = forward_starttime(sol, st, oloca, column, ovehi)
                    else
                        st[node][v, serv] = min_st
                    end
                elseif in_PRE(node, PRE) && in(node, calculated)

                    # find location of pre node
                    other_serv, before_serv = find_other_serv_in_syn_pre(node, serv, PRE, is_pre=true)
                    ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)

                    if before_serv # other service has to process first
                        if min_st - st[node][ovehi, other_serv] < mind[node]
                            st[node][v, serv] = st[node][ovehi, other_serv] + mind[node]
                        elseif min_st - st[node][ovehi, other_serv] > maxd[node]
                            st[node][v, serv] = min_st
                            st[node][ovehi, other_serv] = min_st - maxd[node]
                            st = forward_starttime(sol, st, oloca, column, ovehi)
                        end
                    else
                        if st[node][ovehi, other_serv] - min_st < mind[node]
                            st[node][v, serv] = min_st
                            st[node][ovehi, other_serv] = min_st + mind[node]
                            st = forward_starttime(sol, st, oloca, column, ovehi)
                        elseif st[node][ovehi, other_serv] - min_st > maxd[node]
                            st[node][v, serv] = st[node][ovehi, other_serv] - maxd[node]
                        end
                    end
                else
                    st[node][v, serv] = min_st
                end


                push!(calculated, node)
            end
            # println(" ")
        end
    end
    return st
end


function starttime(sol::Sol, route::Array)
    sol.route = route
    return starttime(sol)
end


function starttime(sol::Sol)
    st = initial_starttime(sol)

    # find max column
    len_route = [length(sol.route[i]) for i in 1:sol.ins.num_vehi]
    maxcolumn = maximum(len_route)

    calculated = Int64[]

    for column in 1:maxcolumn
        for v in 1:sol.ins.num_vehi
            if column <= len_route[v]

                # find departure and arrival node
                if column == 1
                    bnode = 1
                    bserv = 1
                else
                    bnode = sol.route[v][column-1][1]
                    bserv = sol.route[v][column-1][2]
                end
                node = sol.route[v][column][1]
                serv = sol.route[v][column][2]
                
                min_st = st[bnode][v, bserv] + sol.ins.d[bnode, node] + sol.ins.p[v, bserv, bnode]
                if min_st < sol.ins.e[node]
                    min_st = sol.ins.e[node]
                end


                # println("calculate column $column vehicle $v node $(sol.route[v][column])")
                # println("e = $(sol.ins.e[node]), d = $(sol.ins.d[bnode, node]) arrive time = $(st[bnode][v, bserv] + sol.ins.d[bnode, node] + sol.ins.p[v, bserv, bnode])")

                if in_SYN(node, sol.ins.SYN) && in(node, calculated)
                    # find location of syn node
                    other_serv = find_other_serv_in_syn_pre(node, serv, sol.ins.SYN)
                    ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)
                    if min_st < st[node][ovehi, other_serv]
                        # println("update min_st")
                        st[node][v, serv] = st[node][ovehi, other_serv]
                    elseif min_st > st[node][ovehi, other_serv]
                        st[node][v, serv] = min_st
                        st[node][ovehi, other_serv] = min_st
                        st = forward_starttime(sol, st, oloca, column, ovehi)
                    else
                        st[node][v, serv] = min_st
                    end
                elseif in_PRE(node, sol.ins.PRE) && in(node, calculated)

                    # find location of pre node
                    other_serv, before_serv = find_other_serv_in_syn_pre(node, serv, sol.ins.PRE, is_pre=true)
                    ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)

                    if before_serv # other service has to process first
                        if min_st - st[node][ovehi, other_serv] < sol.ins.mind[node]
                            st[node][v, serv] = st[node][ovehi, other_serv] + sol.ins.mind[node]
                        elseif min_st - st[node][ovehi, other_serv] > sol.ins.maxd[node]
                            st[node][v, serv] = min_st
                            st[node][ovehi, other_serv] = min_st - sol.ins.maxd[node]
                            st = forward_starttime(sol, st, oloca, column, ovehi)
                        end
                    else
                        if st[node][ovehi, other_serv] - min_st < sol.ins.mind[node]
                            st[node][v, serv] = min_st
                            st[node][ovehi, other_serv] = min_st + sol.ins.mind[node]
                            st = forward_starttime(sol, st, oloca, column, ovehi)
                        elseif st[node][ovehi, other_serv] - min_st > sol.ins.maxd[node]
                            st[node][v, serv] = st[node][ovehi, other_serv] - sol.ins.maxd[node]
                        end
                    end
                else
                    st[node][v, serv] = min_st
                end


                push!(calculated, node)
            end
            # println(" ")
        end
    end
    return st
end


function PSO(ins::Ins; num_par=15, max_iter=150)
    particles = []
    obj = []

    particles = [generate_particles(ins) for _ in 1:num_par]
    obj = objective_value.(particles)

    # find best particle
    best_index = argmin(obj)
    best_par = particles[best_index]


    # defind parameters
    iter = 1
    old_best = Inf
    new_best = Inf
    not_improve = 1

    # loop
    while iter < max_iter && not_improve < 10

        # save objective_value
        # old_best = new_best

        # local search
        for i in 1:num_par
        # for i in Iterators.filter(x->x!=best_index, 1:num_par)
            particles[i] = local_search(particles[i], best_par)
        end
        # particles = [local_search(particles[i]) for i in 1:num_par]

        # find best particle
        obj = objective_value.(particles)
        best_index = argmin(obj)

        if obj[best_index] < new_best
            new_best = obj[best_index]
            best_par = particles[best_index]
            not_improve = 1
        else
            not_improve += 1
        end

        # if not_improve == 4
        #     particles = [generate_particles(Name) for _ in 1:num_par]
        # end
        
        # if old_best - new_best < 1e4
        #     not_improve += 1
        # end

        println("iter: $iter best[$best_index]: $(@sprintf("%.2f", new_best)), PRE: $(check_PRE(best_par)), SYN: $(check_SYN(best_par)), Compat: $(compatibility(best_par))")
        iter += 1
    end

    # save solution
    # save_particle(best_par, Name)

end