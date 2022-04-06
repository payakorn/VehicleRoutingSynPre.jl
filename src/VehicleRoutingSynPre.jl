module VehicleRoutingSynPre

using JLD2, Random
# Write your package code here.
include("ParticleSwarm.jl")

export Particle,
        load_data,
        generate_particle,
        generate_particles

end
