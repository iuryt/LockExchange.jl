# Importing packages
using Plots
pyplot() #add pyplot from python
using Oceananigans 
using Oceananigans.Units 


L = 20meters #Length in meters (thus x1)
H = 4meters #Total depth

Ny = Int(2*L/0.1meters) # number of points in y
Nz = Int(H/0.1meters) # number of points in z

grid = RectilinearGrid( #creating grid
    size=(Ny, Nz), 
    y=(-L*meters, L*meters),
    z=(-H*meters,0),
    topology=(Flat, Bounded, Bounded) # Solving for y and z where we define as "Bounded". "Flat" will not be solved.
)

closure = SmagorinskyLilly() #Choosing turbulence closure

model = NonhydrostaticModel(grid=grid, closure=closure, buoyancy=SeawaterBuoyancy(), tracers=(:T, :S)) # Setting the model configuration

initial_temperature(x, y, z) = 20 + 0.5*y/abs(y)
set!(model, T=initial_temperature, S=35) # Adding initial conditions to the model setting

simulation = Simulation(model, Δt = 0.025seconds, stop_time = 10minutes) #Creating the simulation

#Setting the format, frequency and path of the output file
simulation.output_writers[:temperature] = JLD2OutputWriter( 
                    model, model.tracers, prefix = "../data/lockexchange",
                    schedule=TimeInterval(30second), force = true
)

run!(simulation)

####################################################################################################
T = FieldTimeSeries("../data/lockexchange.jld2", "T") # Reading the output file
x,y,z = nodes(T) #Extracting the grid

#Creating the animation
anim = @animate for (i, t) in enumerate(T.times)
    contour(y,z,T[1,:,:,i]'; xlabel="y [m]", ylabel="z [m]",clim=(19,20.5),c=cgrad(:dense,rev=true), levels=18.9:0.1:20.5, fill=true, linewidth=0.0)
end

#Saving the animation as a GIF
gif(anim, "../img/animation.gif", fps = 9)