data = readdlm(joinpath(@__DIR__, "..", "data", "chiangmai_data", "traveled_time_matrix.txt"))

# load upper and lower time window
lower_time_window = readdlm(joinpath(@__DIR__, "..", "data", "chiangmai_data", "lower_time_window.txt"))
upper_time_window = readdlm(joinpath(@__DIR__, "..", "data", "chiangmai_data", "upper_time_window.txt"))

# load Synchronization and Precedence node-service
synchromization_node = readdlm(joinpath(@__DIR__, "..", "data", "chiangmai_data", "synchronization.txt"))
precedence_node = readdlm(joinpath(@__DIR__, "..", "data", "chiangmai_data", "precedence.txt"))

