include("cholesky.jl")

# Chordal extension
abstract type AbstractChordalExtension end
mutable struct CholeskyExtension <: AbstractChordalExtension
    shift::Float64
    perm::Union{Nothing, Vector{Int}}
    CholeskyExtension(shift = 0.0, perm = nothing) = new(shift, perm)
end
mutable struct MinimumDegreeExtension <: AbstractChordalExtension end


function chordal_extension(network::PowerFlowNetwork, alg::CholeskyExtension)
    return cholesky_extension(network)
end

function chordal_extension(adj::SparseMatrixCSC, alg::CholeskyExtension)
    return cholesky_extension(adj)
end
