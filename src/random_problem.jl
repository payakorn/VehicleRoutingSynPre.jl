using Random

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

mind = zeros(num_node)
maxd = zeros(num_node)

# generate syn
SYN = []
for i in 427:501
    rrr = rand(1:3)
    println("iter: $i, $(length(findall(x->x==1.0, r[i, :])))")
    if rrr == 1 # syn
        samples = sample(findall(x->x==1.0, r[i, :]), 2, replace=false)
        push!(SYN, (i, samples[1], samples[2]))
    elseif rrr == 2 # pre 
        samples = sample(findall(x->x==1.0, r[i, :]), 2, replace=false)
        push!(PRE, (i, samples[1], samples[2]))
        
    else
        nothing # nothing
    end
end