abstract type AbstractMerge end
mutable struct MolzahnMerge <: AbstractMerge
    L::Float64
    MolzahnMerge(L::Float64=0.1) = new(L)
end
