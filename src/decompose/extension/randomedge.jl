# source: https://github.com/lanl-ansi/PowerModels.jl/blob/master/src/form/wrm.jl#L328
function random_edge_extension(adj::SparseMatrixCSC,
                               nb_edge::Union{Int, Float64},
                               max_dist::Int,
                               max_stable_it::Int,
                               decomposition_alg::AbstractChordalExtension)
    cadj = copy(adj)
    add_random_edge_vertex!(cadj, nb_edge, max_dist, max_stable_it)
    return chordal_extension(cadj, decomposition_alg)
end

function random_edge_extension(network::PowerFlowNetwork,
                               nb_edge::Union{Int, Float64},
                               max_dist::Int,
                               max_stable_it::Int,
                               decomposition_alg::AbstractChordalExtension)
    return random_edge_extension(adjacency_matrix(network), nb_edge, max_dist, max_stable_it, decomposition_alg)
end

function chordal_extension(adj::SparseMatrixCSC, alg::RandomEdgeExtension)
    return random_edge_extension(adj, alg.nb_edge, alg.max_dist, alg.max_stable_it, alg.decomposition_alg)
end

function chordal_extension(network::PowerFlowNetwork, alg::RandomEdgeExtension)
    return random_edge_extension(network, alg.nb_edge, alg.max_dist, alg.max_stable_it, alg.decomposition_alg)
end
