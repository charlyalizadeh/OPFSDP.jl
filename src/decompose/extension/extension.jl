abstract type AbstractChordalExtension end
mutable struct CholeskyExtension <: AbstractChordalExtension
    shift::Float64
    perm::Union{Nothing, Vector{Int}}
    CholeskyExtension(shift = 0.0, perm = nothing) = new(shift, perm)
end
mutable struct MinimumDegreeExtension <: AbstractChordalExtension end
mutable struct RandomEdgeExtension <: AbstractChordalExtension
    nb_edge::Union{Float64, Int}
    max_dist::Int
    max_stable_it::Int
    decomposition_alg::AbstractChordalExtension
    RandomEdgeExtension(nb_edge::Union{Float64, Int},
                        max_dist::Int,
                        max_stable_it::Int,
                        decomposition_alg::AbstractChordalExtension = CholeskyExtension()
                       ) = new(nb_edge, max_dist, max_stable_it, decomposition_alg)
end


