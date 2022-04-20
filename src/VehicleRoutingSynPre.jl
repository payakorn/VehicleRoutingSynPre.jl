module VehicleRoutingSynPre

using JLD2, Random
# Write your package code here.
include("ParticleSwarm.jl")

export Particle,
       load_data,
       generate_particle,
       generate_particles,
       generate_group_of_node,
       find_starttime,
       initial_inserting
end
