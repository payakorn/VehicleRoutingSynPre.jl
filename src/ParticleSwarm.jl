mutable struct Particle
    route::Array
    starttime::Array
    num_node::Int64
    num_vehi::Int64
    num_serv::Int64
    mind::Vector
    maxd::Vector
    distance_matrix::Matrix
    service::Array
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
    generate_group_of_node(num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)

    devide node to compatible vehicle randomly

"""
function generate_group_of_node(num_node::Int64, num_vehi::Int64, a::Matrix, r::Matrix)
    node_vehicle = r*a'
    group_node = [Int64[] for i in 1:num_vehi]
    # group_node = Dict(i => Int64[0] for i in 1:num_vehi)
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


function find_starttime(particle::Particle)
    st = []
    for k in 1:particle.num_vehi
        if particle.distance_matrix[1, particle.route[k][2]] + particle.service[particle.route[k][1]] < particle.e[particle.route[k][2]]
            append!(st, Int64[particle.e[particle.route[k][2]]])
        elseif particle.distance_matrix[1, particle.route[k][2]] > particle.l[particle.route[k][2]]
            throw(particle.distance_matrix[1, particle.route[k][2]] > particle.l[particle.route[k][2]])
        else
            append!(st, Int64[particle.e[particle.route[k][2]]])
        end


        for j in 2:length(particle.route[k])
            nothing
        end

    end
    return st
end


function generate_particle(num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)

    # cluter nodes to vehicle
    group_node = generate_group_of_node(num_node, num_vehi, a, r)

    # juat add
    starttime = []

    return Particle(group_node, starttime, num_node, num_vehi, num_serv, mind, maxd, d, p, e, l, PRE, SYN)
end


function initial_inserting(group_node::Array, num_node::Int64, num_vehi::Int64, num_serv::Int64)
    for vehi in 1:num_vehi
        nothing
    end
end


function generate_particles(name::String; SYN=nothing, PRE=nothing)
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(name)
    if isnothing(SYN)
        SYN = Int64[]
        for i in 2:num_node
            if mind[i] == 0 && maxd[i] == 0
                push!(SYN, i)
            end
        end
    end

    if isnothing(PRE)
        PRE = Int64[]
    end

    generate_particle(num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end