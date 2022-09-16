using Random, Statistics, StatsBase

num_node = 500
num_vehi = 40
num_serv = 6
syn_pre = 50

a = rand(0:1, num_vehi, num_serv)

r = zeros(num_node, num_serv)

for i in 1:425
    ra = rand(1:num_serv)
    r[i, ra] = 1
end

for i in 426:500
    rand_num = rand(2:4)
    while sum(r[i, :]) < rand_num
        rand_ind = rand(1:6)
        r[i, rand_ind] = 1.0
    end
end

r = [ones(1, num_serv);r]
r = [r; ones(1, num_serv)]

mind = zeros(num_node+1)
maxd = zeros(num_node+1)

# generate syn and pre
SYN = []
PRE = []
for i in 427:501
    rrr = rand(1:3)
    println("iter: $i, $(length(findall(x->x==1.0, r[i, :])))")
    if rrr == 1 # syn
        samples = sample(findall(x->x==1.0, r[i, :]), 2, replace=false)
        push!(SYN, (i, samples[1], samples[2]))
    elseif rrr == 2 # pre 
        samples = sample(findall(x->x==1.0, r[i, :]), 2, replace=false)
        push!(PRE, (i, samples[1], samples[2]))
        rand_maxmin = sort(rand(0:50, 2))
        mind[i] = rand_maxmin[1]
        maxd[i] = rand_maxmin[2]
    else
        nothing # nothing
    end
end

# generate location of nodes and calculate the distance matrix 
x = 100*rand(num_node+1)
y = 100*rand(num_node+1)
d = dist(x, y)


# generate processing time
# processing time
p = zeros(Float64, num_vehi, num_serv)
for i in 2:num_node+1
    global p
    p = cat(p, 20.0*ones(Float64, num_vehi, num_serv), dims=3)
end

# generate time windows
el = sort(rand(0:1000, num_node+1, 2), dims=2) # random matrix with 2 columns that column 1 < column 2
e = el[:, 1]
l = el[:, 2]
e[1] = 0

serv_r = find_service_request(r)
serv_a = find_compat_vehicle_node(a, r)
inss = Ins("ins$(num_node-1)-1", num_node, num_vehi, num_serv, serv_a, serv_r, mind, maxd, a, r, d, p, e, l, PRE, SYN)