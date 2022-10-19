count = 1

for i in 1:6
    for j in 1:6
        for k in 1:6
            if i <= j <= k
                println("$count: $i <= $j <= $k")
                count += 1
            end
        end
    end
end