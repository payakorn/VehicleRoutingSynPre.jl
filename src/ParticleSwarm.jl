mutable struct Particle
    route::Array
    starttime::Array
    slot::Dict{Int64, Vector{Int64}}
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


function find_starttime(route::Array, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    st = [Float64[0] for i in 1:num_vehi]
    for k in 1:num_vehi
        for j in 2:length(route[k])
            comptime = st[k][j-1] + d[route[k][j-1], route[k][j]] + p[k, 1, route[k][j]]
            if comptime < e[route[k][j]]
                push!(st[k], e[route[k][j]])
            else
                push!(st[k], comptime)
            end
        end
    end
    return st
end


function find_empty_service(num_node::Int64)
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
    return find_starttime(par.route, par.num_node, par.num_vehi, par.num_serv, par.mind, par.maxd, par.a, par.r, par.d, par.p, par.e, par.l, par.PRE, par.SYN)
end


function find_service(par::Particle)
    return find_service(par.route, par.num_node, par.num_vehi, par.num_serv, par.mind, par.maxd, par.a, par.r, par.d, par.p, par.e, par.l, par.PRE, par.SYN)
end


function generate_particle(num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)

    # cluter nodes to vehicle
    group_node = find_group_of_node(num_node, num_vehi, a, r)

    # just add
    starttime = find_starttime(group_node, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, SYN, PRE)
    service = find_empty_service(num_node)

    return Particle(group_node, starttime, service, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end


function initial_inserting(group_node::Array, num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    condidate = Int64[]
    remaining = Int64[]
    for vehi in 1:num_vehi
        union!(candidate, group_node[vehi])
        test_par = deepcopy(par)
    end
end


function find_SYN(mind::Vector, maxd::Vector)
    SYN = Int64[]
    for i in 2:length(mind)-1
        if mind[i] == 0 && maxd[i] == 0
            push!(SYN, i)
        end
    end
    return SYN
end


function find_PRE(mind::Vector, maxd::Vector)
    nothing
end


function generate_particles(name::String; SYN=nothing, PRE=nothing)
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(name)

    SYN = find_SYN(mind, maxd)

    generate_particle(num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end


function insert_service_to_node_slot(particle::Particle, node::Int64, slot::Int64)
    nothing
end