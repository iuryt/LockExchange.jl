using Plots
using Oceananigans
using Oceananigans.Units


L = 20meters
H = 4meters

Ny = Int(2*L/0.1meters) # number of points in y
Nz = Int(H/0.1meters) # number of points in z

grid = RectilinearGrid(
    size=(Ny, Nz), 
    y=(-L*meters, L*meters), 
    z=(-H*meters,0),
    topology=(Flat, Bounded, Bounded)
)

closure = SmagorinskyLilly()

model = NonhydrostaticModel(grid=grid, closure=closure, buoyancy=SeawaterBuoyancy(), tracers=(:T, :S))

initial_temperature(x, y, z) = 20 + 0.5*y/abs(y)
set!(model, T=initial_temperature, S=35)

simulation = Simulation(model, Δt = 0.1seconds, stop_time = 10minutes)

simulation.output_writers[:temperature] = JLD2OutputWriter(
                    model, model.tracers, prefix = "../data/lockexchange",
                    schedule=TimeInterval(1minute), force = true
)

run!(simulation)

T = FieldTimeSeries("../data/lockexchange.jld2", "T")
x,y,z = nodes(T)


anim = @animate for (i, t) in enumerate(T.times)
    contour(y,z,T[1,:,:,i]'; xlabel="y [m]", ylabel="z [m]", levels=18.5:0.1:21.5, fill=true, linewidth=0.2)
end

mp4(anim, "../img/animation.mp4", fps = 2)