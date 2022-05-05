mutable struct Particle
    route::Vector{Vector{Vector{Int64}}}
    starttime::Dict{Int64, Array{Float64}}
    slot::Dict{Int64, Vector{Int64}}
    serv_a::Tuple
    serv_r::Dict{Int64, Vector{Int64}}
    num_node::Int64
    num_vehi::Int64
    num_serv::Int64
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


"""
    load_data(name::String) 

    return number of node (including depot), number of vehicle, number of services, min precedence, max, precedence, matrix 'a', matrix 'r', distance, processing time, earliest, latest duedate

    Example:

    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data("ins10-1")
"""
function load_data(name::String)
    f = load(joinpath(@__DIR__, "..", "data", "raw_HHCRSP", "$name.jld2"))
    return f["num_node"], f["num_vehi"], f["num_serv"], f["mind"], f["maxd"], f["a"], f["r"], f["d"], f["p"], f["e"], f["l"]
end


"""
    find_group_of_node(num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)

    devide node to compatible vehicle randomly

"""
function find_group_of_node(num_node::Int64, num_vehi::Int64, a::Matrix, r::Matrix)
    node_vehicle = r*a'
    group_node = [Int64[] for i in 1:num_vehi]
    # group_node = Dict(i => Int64[1] for i in 1:num_vehi)
    for i in 2:num_node
        if sum(r[i, :]) == 1
            push!(group_node[rand(findall(x->x==1, node_vehicle[i, :]))], i)
        else
            jobs = findall(x -> x > 0, node_vehicle[i, :])
            for j in jobs
                push!(group_node[j], i)
            end
        end
    end
    return group_node
end


function find_vehicle_by_service(route::Array, node::Int64, service::Int64, num_vehi::Int64)
    for vehi in 1:num_vehi
        for i in route[vehi]
            if issubset((node, service), i)
                return vehi
            end
        end
    end
    return nothing
end


function find_starttime(route::Array, slot::Dict{Int64, Vector{Int64}}, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    st = Dict(i => zeros(Float64, num_vehi, num_serv) for i in 0:num_node)

    for vehi in 1:num_vehi
        for i in 1:length(route[vehi])
            if i == 1 # start at node 1 (origin)
                left = 1
                right = route[vehi][i][1]

                if d[left, right] > e[route[vehi][i][1]]
                    st[right][vehi, route[vehi][i][2]] = d[left, right]
                else
                    st[right][vehi, route[vehi][i][2]] = e[route[vehi][i][1]]
                end

                # if right != 1
                #     for sl in 2:length(slot[right])
                #         v = find_vehicle_by_service(route, right, slot[right][sl-1], num_vehi)
                #         st[right][v, slot[right][sl]] = maximum(st[right][slot[right][sl-1]])
                #     end
                # end
            else
                left = route[vehi][i-1][1]
                right = route[vehi][i][1]

                if st[left][vehi, route[vehi][i-1][2]] + p[vehi, route[vehi][i-1][2], left] + d[left, right] > e[route[vehi][i][1]]
                    st[right][vehi, route[vehi][i][2]] = st[left][vehi, route[vehi][i-1][2]] + p[vehi, route[vehi][i-1][2], left] + d[left, right]
                else
                    st[right][vehi, route[vehi][i][2]] = e[route[vehi][i][1]]
                end

                println("vehi: $vehi st[$right][$vehi, route[$vehi][$i][2]] = $(st[right][vehi, route[vehi][i][2]])" )

            end

            if right != 1
                for sl in 2:length(slot[right])
                    v = find_vehicle_by_service(route, right, slot[right][sl], num_vehi)
                    if any([(right, slot[right][sl-1], slot[right][sl]) == i || (right, slot[right][sl], slot[right][sl-1]) == i for i in SYN]) # synchronization
                        if maximum(st[right][:, slot[right][sl-1]]) > st[right][v, slot[right][sl]]
                            st[right][v, slot[right][sl]] = maximum(st[right][:, slot[right][sl-1]])
                        elseif maximum(st[right][:, slot[right][sl-1]]) < st[right][v, slot[right][sl]]
                            diff_starttime = st[right][v, slot[right][sl]] - maximum(st[right][:, slot[right][sl-1]])
                            # st[right][v, slot[right][sl]] = st[right][v, slot[right][sl]]
                            # vv = find_vehicle_by_service(route, right, slot[right][sl-1], num_vehi)
                            vv, loca = find_location_by_node_service(route, right, slot[right][sl-1])
                            st[right][vv, slot[right][sl-1]] = st[right][v, slot[right][sl]]
                            for k in loca+1:length(route[vv])
                                st[route[vv][k][1]][vv, route[vv][k][2]] += diff_starttime
                            end
                        end
                    elseif any([(right, slot[right][sl-1], slot[right][sl]) == i for i in PRE]) # precedence
                        # @show right
                        # @show v
                        # before_vehi = argmax(st[right][:, slot[right][sl-1]])
                        starttime_before_vehi = st[right][:, slot[right][sl-1]][vehi]
                        # st[right][v, slot[right][sl]] = maximum((starttime_before_vehi, st[right][v, slot[right][sl]]))
                        if st[right][v, slot[right][sl]] - st[right][vehi, slot[right][sl-1]] < mind[right]
                            if vehi != v # if they come from different vehicles
                                st[right][v, slot[right][sl]] += (mind[right] - (st[right][v, slot[right][sl]] - st[right][vehi, slot[right][sl-1]]))
                                # if st[right][v, slot[right][sl-1]] + p[v, slot[right][sl-1], right] > st[right][v, slot[right][sl]]
                                #     st[right][v, slot[right][sl]] = st[right][v, slot[right][sl-1]] + p[v, slot[right][sl-1], right]
                                # end
                            else
                                if st[right][v, slot[right][sl]] - (st[right][vehi, slot[right][sl-1]] + p[vehi, slot[right][sl-1], right]) < mind[right]
                                    st[right][v, slot[right][sl]] += st[right][v, slot[right][sl]] - (st[right][vehi, slot[right][sl-1]] + p[vehi, slot[right][sl-1], right])
                                end
                            end
                        end
                    else
                        st[right][v, slot[right][sl]] = maximum(maximum(st[right][:, slot[right][sl-1]]) + p[v, slot[right][sl-1], right], st[right][v, slot[right][sl]])
                    end
                end
            end
            # println("vehicle: $vehi, depart: $left, arrive: $right, start $(st[right][vehi, route[vehi][i][2]])")
        end
    end
    return st
end


function create_empty_slot(num_node::Int64)
    return Dict(i => Int64[] for i in 2:num_node)
end


function find_service_request(r::Array)
    # serv_requst = [findall(x->x==1, r[2, :])]
    # for node in 3:size(r, 1)-1
    #     append!(serv_requst, [findall(x->x==1, r[node, :])])
    # end
    # return serv_requst
    return Dict(node => findall(x->x==1, r[node, :]) for node in 2:size(r, 1)-1)
end


function find_starttime(par::Particle)
    return find_starttime(par.route, par.slot, par.num_node, par.num_vehi, par.num_serv, par.mind, par.maxd, par.a, par.r, par.d, par.p, par.e, par.l, par.PRE, par.SYN)
end


function find_service(par::Particle)
    return find_service(par.route, par.num_node, par.num_vehi, par.num_serv, par.mind, par.maxd, par.a, par.r, par.d, par.p, par.e, par.l, par.PRE, par.SYN)
end


function generate_empty_particle(serv_a::Tuple, serv_r::Dict, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)

    # cluter nodes to vehicle
    group_node = find_group_of_node(num_node, num_vehi, a, r)

    # create empty route
    route = [[Int64[1, 1]] for _ in 1:num_vehi]
    # route = [[[1, 1]], [[9, 5], [1, 1]], [[2, 4], [9, 6], [1, 1]]] # for test

    # create empty slot
    slot = create_empty_slot(num_node)
    # slot[9] = [5, 6]

    # just add
    # starttime = find_starttime(route, num_node, slot, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, SYN, PRE)
    starttime = find_starttime(route, slot, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
    # service = create_empty_slot(num_node)

    return Particle(route, starttime, slot, serv_a, serv_r, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end


function initial_insert_service(serv_r::Dict{Int64, Vector{Int64}}, num_node::Int64, num_vehi::Int64, num_serv::Int64, SYN::Vector{Tuple})
    slot = deepcopy(serv_r)
    for serv in slot
        slot[serv[1]] = [rand(serv[2])]
    end

    # SYN
    for syn in SYN
        slot[syn[1]] = collect(syn[2:end])
    end
    return slot
end


function check_assigned_node(route::Array, node::Int64, service::Int64, num_vehi::Int64)
    for vehi in 1:num_vehi
        if [node, service] in route[vehi]
            return true
        end
    end
    return false
end


function insert_vehicle_to_service(route::Array, slot::Dict{Int64, Vector{Int64}}, num_node::Int64, num_vehi::Int64, a::Matrix, e::Vector, SYN::Vector, PRE::Vector)
    for syn in SYN
        for i in 2:length(syn)-1
            if !check_assigned_node(route, syn[1], syn[i], num_vehi) && !check_assigned_node(route, syn[1], syn[i+1], num_vehi) && issubset([syn[i], syn[i+1]], slot[syn[1]])
                vehi1 = rand(findall(x->x==1, a[:, syn[i]]))
                vehi2 = rand(setdiff(findall(x->x==1, a[:, syn[i+1]]), vehi1))
                insert!(route[vehi1], 1, [syn[1], syn[i]])
                insert!(route[vehi2], 1, [syn[1], syn[i+1]])
            end
        end
    end
    
    for node in setdiff(sortperm(e)[3:end], [sl[1] for sl in SYN])
        # println("$node, $(slot[node])")
        for sl in slot[node]
            if !check_assigned_node(route, node, sl, num_vehi)
                vehi = rand(findall(x->x==1, a[:, sl]))
                insert!(route[vehi], length(route[vehi]), [node, sl])
            end
        end
    end
    return route
end


function insert_vehicle_to_service(particle::Particle)
    particle.route = insert_vehicle_to_service(particle.route, particle.slot, particle.num_node, particle.num_vehi, particle.a, particle.e, particle.SYN, particle.PRE)
    particle.starttime = find_starttime(particle)
    return particle
end


function find_SYN(serv_request::Dict, mind::Vector, maxd::Vector)
    SYN = Tuple[]
    for i in 2:length(mind)-1
        if mind[i] == 0 && maxd[i] == 0
            push!(SYN, (i, serv_request[i]...))
        end
    end
    return SYN
end

"""
    function find_PRE(serv_request::Dict)

        (node, service1, service2) => service1 must start before service2 at the node 

"""
function find_PRE(serv_request::Dict, mind::Array, maxd::Array)
    PRE = Tuple[]
    for i in 2:length(serv_request)+1
        if length(serv_request[i]) > 1
            if mind[i] != 0 && maxd[i] != 0
                for j in 1:length(serv_request[i])-1
                    push!(PRE, (i, serv_request[i][j], serv_request[i][j+1]))
                end
            end
        end
    end
    return PRE
end


function find_vehicle_service(a::Matrix)
    vehicle_compat = collect(Tuple(findall(x->x==1, a[vehi, :])) for vehi in 1:size(a, 1))
    return vehicle_compat
end


function find_compat_vehicle_node(a::Array, r::Array)
    compat_matrix = a*r'
    return Tuple(Tuple(findall(x->x>0, compat_matrix[i, :])) for i in 1:size(compat_matrix, 1))
end


function generate_particles(name::String)
    # load data
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(name)

    # find Synchronization and Precedence constraints
    serv_r = find_service_request(r)
    serv_a = find_compat_vehicle_node(a, r)
    SYN = find_SYN(serv_r, mind, maxd)
    PRE = find_PRE(serv_r, mind, maxd)



    par = generate_empty_particle(serv_a, serv_r, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
    par.slot = initial_insert_service(serv_r, num_node, num_vehi, num_serv, SYN)
    par = insert_vehicle_to_service(par)
    par = insert_PRE(par)
end


function find_remain_service(slot::Dict, serv_r::Dict)
    for (i, sl) in slot
        try setdiff!(serv_r[i], slot[i]) catch e; continue end
        if isempty(serv_r[i])
            delete!(serv_r, i)
        end
    end
    return serv_r
end


function find_remain_service(particle::Particle)
    return find_remain_service(particle.slot, particle.serv_r)
end


function find_location_by_node_service(route::Array, node::Int64, service::Int64)
    for (num_v, vehi) in enumerate(route)
        for (num_loca, n) in enumerate(vehi)
            if [node, service] == [n[1], n[2]]
                return (num_v, num_loca)
            end
        end
    end
end


function insert_PRE(route::Array, slot::Dict{Int64, Vector{Int64}}, num_vehi::Int64, serv_r::Dict{Int64, Vector{Int64}}, PRE::Vector{Tuple})
    serv_r = find_remain_service(slot, serv_r)
    for (node, remain_service) in serv_r
        for serv in remain_service
            # check Precedence
            for pre_service in findall(issubset.((node, serv), PRE))
                location = findfirst(x->x==serv, PRE[pre_service])
                if location == 2
                    insert!(slot[node], findfirst(x->x==PRE[pre_service][3], slot[node]), PRE[pre_service][2])
                    (v, loca) = find_location_by_node_service(route, node, slot[node][findfirst(x->x==PRE[pre_service][3], slot[node])])
                    insert!(route[v], loca, [node, PRE[pre_service][2]])
                else
                    insert!(slot[node], findfirst(x->x==PRE[pre_service][2], slot[node])+1, PRE[pre_service][3])
                    (v, loca) = find_location_by_node_service(route, node, slot[node][findfirst(x->x==PRE[pre_service][2], slot[node])])
                    insert!(route[v], loca+1, [node, PRE[pre_service][3]])
                end
            end
        end
    end
    return route, slot, serv_r
end


function insert_PRE(particle::Particle)
    route, slot, serv_r = insert_PRE(particle.route, particle.slot, particle.num_vehi, particle.serv_r, particle.PRE)
    particle.route = route
    particle.slot = slot
    particle.serv_r = serv_r
    particle.starttime = find_starttime(particle)
    return particle
end


function insert_service_to_node_slot(particle::Particle, node::Int64, slot::Int64)
    nothing
end


function compatibility(particle::Particle)
    return compatibility(particle.route, particle.slot, particle.a, particle.r, particle.serv_a, particle.serv_r)
end


function compatibility(route::Array, slot::Dict, a::Matrix, r::Matrix, serv_a::Tuple, serv_r::Dict)

    # check services
    for sl in slot
        if !issubset(sl[2], serv_r[sl[1]])
            println("incompat $(sl[2]) not in $(serv_r[sl[1]])")
            return false
        end
    end

    # check node
    comp_matrix = a*r' .> 0
    for vehi in 1:size(a, 1)
        for node in route[vehi]
            if !in(node[1], serv_a[vehi])
                println("false $(node[1])")
                return false
            end
        end
    end
    return true
end


function feasibility(particle::Particle)
    if !compatibility(particle)
        return false
    else
        return true
    end
end


function insert_initial_SYN(particle::Particle)
    nothing
end


function total_distance(route::Array, d::Matrix)
    dis = 0.0
    route1 = deepcopy(route)
    for vehi in route1
        insert!(vehi, 1, [1, 1])
        for node in 1:length(vehi)-1
            dis += d[vehi[node][1], vehi[node+1][1]]
        end
    end
    return dis
end


function total_distance(particle::Particle)
    return total_distance(particle.route, particle.d)
end


function tardiness(route::Array, starttime::Dict, p::Array, l::Vector)
    tardy = 0.0
    max_tardy = 0.0
    for (i, vehi) in enumerate(route)
        for node_service in vehi
            st = starttime[node_service[1]][i, node_service[2]] - l[node_service[1]]
            if st > 0.0
                tardy += st
                if st > max_tardy
                    max_tardy = deepcopy(st)
                end
            end
        end
    end 
    return tardy, max_tardy
end


function tardiness(particle::Particle)
    return tardiness(particle.route, particle.starttime, particle.p, particle.l)
end


function objective_value(particle::Particle; lambda=[1/3, 1/3, 1/3])
    tardy, max_tardy = tardiness(particle)
    return lambda[1]*total_distance(particle) + lambda[2]*tardy + lambda[3]*max_tardy
end


function example()
    route = [
        [[11, 3], [4, 2], [6, 3], [10, 1], [8, 3], [1, 1]],
        [[9, 6], [1, 1]],
        [[9, 5], [11, 6], [7, 5], [2, 4], [3, 5], [10, 4], [5, 4], [1, 1]]
    ]
    
    slot = Dict(i => Int64[] for i in 2:11)
    slot[2] = [4]
    slot[3] = [5]
    slot[4] = [2]
    slot[5] = [4]
    slot[6] = [3]
    slot[7] = [5]
    slot[8] = [3]
    slot[9] = [5, 6]
    slot[10] = [1, 4]
    slot[11] = [3, 6]

    return route, slot
end


function example2()
    route = [
        [[10, 1], [3, 1], [4, 3], [8, 1], [11, 3], [5, 2], [7, 1], [1, 1]],
        [[2, 5], [9, 4], [11, 5], [1, 1]],
        [[10, 6], [9, 5], [6, 4], [1, 1]]
    ]
    
    slot = Dict(i => Int64[] for i in 2:11)
    slot[2] = [5]
    slot[3] = [1]
    slot[4] = [3]
    slot[5] = [2]
    slot[6] = [4]
    slot[7] = [1]
    slot[8] = [1]
    slot[9] = [4, 5]
    slot[10] = [1, 6]
    slot[11] = [3, 5]

    return route, slot
end


function generate_example()
    route, slot = example()
    par = generate_particles("ins10-1")
    par.route = route
    par.slot = slot
    par.starttime = find_starttime(par)
    return par
end


function complete(route, slot)
    nothing
end


function complete(particle::Particle)
    nothing
end