using VehicleRoutingSynPre
using Test

particle = generate_particles("ins10-1");
particle.route, particle.slot = example();
particle.starttime = find_starttime(particle)

@testset "VehicleRoutingSynPre.jl" begin
    # Write your tests here.
    @test objective_value(particle) - 218.19855033333334 < 1e-3
end
