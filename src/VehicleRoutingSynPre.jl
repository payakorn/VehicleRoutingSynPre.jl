module VehicleRoutingSynPre

using JLD2, Random
# Write your package code here.
include("ParticleSwarm.jl")

export Particle,
       load_data,
       generate_empty_particle,
       generate_particles,
       find_group_of_node,
       find_starttime,
       initial_inserting,
       find_service_request,
       find_SYN,
       find_PRE,
       find_vehicle_service,
       feasibility,
       compatibility,
       find_compat_vehicle_node,
       create_empty_slot,
       find_vehicle_by_service,
       example
end
