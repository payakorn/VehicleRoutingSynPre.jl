mutable struct Particle
    route::Array
    starttime::Dict{Int64, Array{Int64}}
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


function find_starttime(route::Array, slot::Dict{Int64, Vector{Int64}}, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    st = Dict(i => zeros(Float64, num_vehi, num_serv) for i in 1:num_node)
    for vehi in 1:num_vehi

        if length(route[vehi]) > 1

            # first node
            if d[1, route[vehi][1]] > e[route[vehi][1]]
                st[route[vehi][1]][vehi, slot[route[vehi][1]]] .= d[1, route[vehi][1]]
            else 
                st[route[vehi][1]][vehi, slot[route[vehi][1]]] .= e[route[vehi][1]] 
            end
            
            # middle node (bug when last service not processed by vehi)
            for i in 2:length(route[vehi])-1
                comptime = maximum(st[route[vehi][i-1]][vehi, :]) + p[vehi, slot[route[vehi][i-1]][end], route[vehi][i-1]] + d[route[vehi][i-1], route[vehi][i]]
                if comptime > e[route[vehi][i]]
                    st[route[vehi][i]][vehi, slot[route[vehi][i]]] .= comptime
                else 
                    st[route[vehi][i]][vehi, slot[route[vehi][i]]] .= e[route[vehi][i]] 
                end
            end

            # last node
        end
    end
    return st
end


function find_starttime2(route::Array, slot::Dict{Int64, Vector{Int64}}, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    # st = [Float64[0] for i in 1:num_vehi]
    # for k in 1:num_vehi
    #     for j in 2:length(route[k])
    #         comptime = st[k][j-1] + d[route[k][j-1], route[k][j]] + p[k, 1, route[k][j]]
    #         if comptime < e[route[k][j]]
    #             push!(st[k], e[route[k][j]])
    #         else
    #             push!(st[k], comptime)
    #         end
    #     end
    # end
    # return st

    st = Dict(i => Float64[] for i in 2:num_node)
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
    route = [Int64[1] for _ in 1:num_vehi]

    # create empty slot
    slot = create_empty_slot(num_node)
    slot_vehi = create_empty_slot(num_node)

    # just add
    # starttime = find_starttime(route, num_node, slot, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, SYN, PRE)
    starttime = find_starttime(route, slot, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
    # service = create_empty_slot(num_node)

    return Particle(route, starttime, slot, slot_vehi, serv_a, serv_r, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end


function initial_inserting(group_node::Array, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    condidate = Int64[]
    remaining = Int64[]
    for vehi in 1:num_vehi
        union!(candidate, group_node[vehi])
        test_par = deepcopy(par)
    end
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


function insert_service_to_node_slot(particle::Particle, node::Int64, slot::Int64)
    nothing
end


function compatibility(particle::Particle)
    return compatibility(particle.route, particle.slot, particle.serv_a, particle.serv_r)
end


function compatibility(route::Array, slot::Dict, serv_a::Tuple, serv_r::Dict)

    # check services
    for sl in slot
        if !issubset(sl[2], serv_r[sl[1]])
            return false
        end
    end

    # check node
    if all(issubset.(route, serv_a))
        return true
    else
        return false
    end
end


function feasibility(particle::Particle)
    if !compatibility(particle)
        return false
    else
        return true
    end
end


function insert_initial_SYN(particle.::Particle)
    nothing
end