mutable struct Particle
    route::Array
    e::Array
    l::Array
    distance_matrix::Array
    service::Array
    mind::Array
    maxd::Array
    PRE::Tuple
    SYN::Tuple
end


function load_data(name::String)
    f = load(joinpath(@__DIR__, "..", "data", "raw_HHCRSP", "$name.jld2"))
    return f["num_node"], f["num_vehi"], f["num_serv"], f["mind"], f["maxd"], f["a"], f["r"], f["d"], f["p"]
end


function generate_particle(num_node::Int64, num_vehi::Int64, num_serv::Int64, mind::Vector, maxd::Array, a::Matrix, r::Matrix, d::Matrix, p::Array)
    route = vcat(1, append!(collect(2:num_node), ones(num_vehi-1))[randcycle(num_node+num_vehi-2)], 1)
end


function generate_particles(name::String)
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p = load_data(name)
    generate_particle(num_node, num_vehi, num_serv, mind, maxd, a, r, d, p)
end