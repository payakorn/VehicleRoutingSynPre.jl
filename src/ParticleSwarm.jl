mutable struct Particle
    route::Array
    starttime::Dict{Int64, Array{Float64}}
    slot::Dict{Int64, Vector{Int64}}
    slot_vehi::Dict{Int64, Vector{Int64}}
    serv_a::Tuple
    serv_r::Dict
    num_node::Int64
    num_vehi::Int64
    num_serv::Int64
    mind::Vector
    maxd::Vector
    a::Array
    r::Array
    d::Matrix
    p::Array
    e::Vector
    l::Vector
    PRE::Vector
    SYN::Vector
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
            if i == 1
                left = 1
                right = route[vehi][i][1]

                if d[left, right] > e[route[vehi][i][1]]
                    st[right][vehi, route[vehi][i][2]] = d[left, right]
                else
                    st[right][vehi, route[vehi][i][2]] = e[route[vehi][i][1]]
                end

                if right != 1
                    for sl in 2:length(slot[right])
                        v = find_vehicle_by_service(route, right, slot[right][sl-1], num_vehi)
                        st[right][v, slot[right][sl]] = maximum(st[right][slot[right][sl-1]])
                    end
                end
            else
                left = route[vehi][i-1][1]
                right = route[vehi][i][1]

                if st[left][vehi, route[vehi][i-1][2]] + p[vehi, route[vehi][i-1][2], left] + d[left, right] > e[route[vehi][i][1]]
                    st[right][vehi, route[vehi][i][2]] = st[left][vehi, route[vehi][i-1][2]] + p[vehi, route[vehi][i-1][2], left] + d[left, right]
                else
                    st[right][vehi, route[vehi][i][2]] = e[route[vehi][i][1]]
                end

                if right != 1
                    for sl in 2:length(slot[right])
                        v = find_vehicle_by_service(route, right, slot[right][sl], num_vehi)
                        st[right][v, slot[right][sl]] = maximum((maximum(st[right][:, slot[right][sl-1]]) + p[v, slot[right][sl-1], right], st[right][v, slot[right][sl]]))
                    end
                end
            end
            println("vehicle: $vehi, depart: $left, arrive: $right, start $(st[right][vehi, route[vehi][i][2]])")
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
    slot_vehi = create_empty_slot(num_node)

    # just add
    # starttime = find_starttime(route, num_node, slot, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, SYN, PRE)
    starttime = find_starttime(route, slot, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
    # service = create_empty_slot(num_node)

    return Particle(route, starttime, slot, slot_vehi, serv_a, serv_r, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
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


function random_insert_vehicle_to_service(route::Array, slot::Dict{Int64, Vector{Int64}}, num_node::Int64, num_vehi::Int64, a::Matrix, e::Vector, SYN::Vector, PRE::Vector)
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
        println("$node, $(slot[node])")
        for sl in slot[node]
            if !check_assigned_node(route, node, sl, num_vehi)
                vehi = rand(findall(x->x==1, a[:, sl]))
                insert!(route[vehi], length(route[vehi]), [node, sl])
            end
        end
    end
    return route
end


function random_insert_vehicle_to_service(particle::Particle)
    particle.route = random_insert_vehicle_to_service(particle.route, particle.slot, particle.num_node, particle.num_vehi, particle.a, particle.e, particle.SYN, particle.PRE)
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
end


function find_remain_service(slot::Dict, serv_r::Dict)
    for (i, sl) in slot
        setdiff!(serv_r[i], slot[i])
    end
    return serv_r
end


function find_remain_service(particle::Particle)
    return find_remain_service(particle.slot, particle.serv_r)
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
            st = starttime[node_service[1]][i, node_service[2]] + p[i, node_service[2], node_service[1]] - l[node_service[1]]
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


function example(route, slot)
    route = [
        [(11, 3), (4, 2), (6, 3), (10, 1), (8, 3), (1, 1)],
        [(9, 6), (1, 1)],
        [(9, 5), (11, 6), (7, 5), (2, 4), (3, 5), (10, 4), (5, 4), (1, 1)]
    ]
    
    slot[2] = [4]
    slot[3] = [5]
    slot[4] = [2]
    slot[5] = [4]
    slot[6] = [3]
    slot[7] = [5]
    slot[8] = [3]
    slot[9] = [5]
    slot[10] = [1, 4]
    slot[11] = [3, 6]

    return route, slot
end