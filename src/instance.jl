struct Ins
    name::String
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


mutable struct Sol
    route::Array
    slot::Dict
    ins::Ins
end


function load_ins(Name::String)
    num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l = load_data(Name)

    # find Synchronization and Precedence constraints
    serv_r = find_service_request(r)
    serv_a = find_compat_vehicle_node(a, r)
    SYN = find_SYN(serv_r, mind, maxd)
    PRE = find_PRE(serv_r, mind, maxd)
    return Ins(Name, num_node, num_vehi, num_serv, mind, maxd, a, r, d, p, e, l, PRE, SYN)
end


function sortperm(ins::Ins)
    setdiff(sortperm(ins.l), [1, 12])
end


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