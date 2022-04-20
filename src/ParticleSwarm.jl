mutable struct Particle
    route::Array
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


function generate_particle(num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array, e::Array, l::Array, PRE::Array, SYN::Array)
    node_vehicle = r*a'
    group_node = [Int64[0] for i in 1:num_vehi]
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
    for k in 1:num_vehi
        push!(group_node[k], 0)
    end
    # return group_node
    return Particle(group_node, num_node, num_vehi, num_serv, mind, maxd, d, p, e, l, PRE, SYN)
end


function initial_inserting(particle::Particle)
    for j in candidate
        nothing
    end
end


function generate_particles(name::String)
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(name)
    SYN = Int64[]
    PRE = Int64[]
    for i in 2:num_node
        if mind[i] == 0 && maxd[i] == 0
            push!(SYN, i)
        end
    end
    generate_particle(num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end