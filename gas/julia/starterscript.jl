#start script
include("findnearest.jl")
include("findneighbours.jl")
include("removeedge.jl")
include("removenode_old.jl")
include("gwr.jl")
include("plotgwr.jl")

using MAT
using PyPlot

#using CPUtime
file = matopen("../local_uniform_2d.mat")
Data = read(file, "Data")
# scatter(Data[1,:]',Data[2,:]', )

tic()
A,(),(),() = gwr(Data,200);
toc()  

scatter(A[1,:]', A[2,:]')