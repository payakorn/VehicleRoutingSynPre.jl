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


function inserted_node(sol::Sol)
    an = all_node_serv(sol.ins)
    all_node = Vector{Int64}[]
    for i in 1:sol.ins.num_vehi
        append!(all_node, sol.route[i])
    end

    setdiff!(an, all_node)

    return an
end


function total_distance(sol::Sol)
    return total_distance(sol.route, sol.ins.d)
end


function tardiness(sol::Sol)
    return tardiness(sol.route, find_starttime(sol), sol.ins.p, sol.ins.l)
end


function objective_value(sol::Sol)
    return objective_value(sol.route, find_starttime(sol), sol.ins.p, sol.ins.l, sol.ins.d)
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
                println("node: $node, has 1 service")
            else
                println("node: $node, has 2 services")
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


function swap(sol::Sol, list)
    sol.route = swap(sol.route, sol.slot, sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv, sol.ins.mind, sol.ins.maxd, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.d, sol.ins.p, sol.ins.e, sol.ins.l, sol.ins.PRE, sol.ins.SYN, list)
    return sol
end


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


function initial_starttime(sol::Sol)
    initial_starttime(sol.ins.num_node, sol.ins.num_vehi, sol.ins.num_serv)
end


function find_other_serv_in_syn_pre(node, serv, SET)
    pre = SET[findfirst(x->x[1]==node, SET)]
    other_serv = setdiff(pre, [node, serv])[1]
    return other_serv
end


function check_SYN(sol::Sol)
    check_SYN(sol.route, sol.ins.SYN)
end


function check_PRE(sol::Sol)
    check_PRE(sol.route ,find_starttime(sol), sol.ins.maxd, sol.ins.PRE)
end


function compatibility(sol::Sol)
    compatibility(sol.route, sol.slot, sol.ins.a, sol.ins.r, sol.ins.serv_a, sol.ins.serv_r, sol.ins.PRE, sol.ins.SYN)
end


function forward_starttime(st::Dict, start_lo, stop_lo, vehi)
    nothing
end


function starttime(sol::Sol)
    st = initial_starttime(sol)

    # find max column
    len_route = [length(sol.route[i]) for i in 1:sol.ins.num_vehi]
    @show maxcolumn = maximum(len_route)

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


                println("calculate column $column vehicle $v node $(sol.route[v][column])")
                println("e = $(sol.ins.e[node]), d = $(sol.ins.d[bnode, node]) arrive time = $(st[bnode][v, bserv] + sol.ins.d[bnode, node] + sol.ins.p[v, bserv, bnode])")

                if in_SYN(node, sol.ins.SYN) && in(node, calculated)
                    # find location of syn node
                    other_serv = find_other_serv_in_syn_pre(node, serv, sol.ins.SYN)
                    @show ovehi, oloca = find_location_by_node_service(sol.route, node, other_serv)
                    if min_st < st[node][ovehi, other_serv]
                        println("update min_st")
                        st[node][vehi, serv] = st[node][ovehi, other_serv]
                    elseif min_st < st[node][ovehi, other_serv]
                        nothing
                    else
                        st[node][v, serv] = min_st
                    end
                elseif in_PRE(node, sol.ins.PRE) && in(node, calculated)
                    nothing
                else
                    st[node][v, serv] = min_st
                end


                push!(calculated, node)
            end
            println(" ")
        end
    end
    return st
end