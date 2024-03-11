"""
    is_chordal = check_chordal(adj)

Return `true` if the adjacency matrix `adj` corresponds to a chordal graph.
"""
function check_chordal(adj::SparseMatrixCSC)
    peo = _mcs(adj)
    for i in 1:length(peo)-1
        if !_check_neighboor_complete(adj, peo[i], peo[i:end])
            return false
        end
    end
    return true
end


"""
    is_complete = _check_neighboor_complete(adj, v, v_sub)

Return `true` if the neighbors of `v` in the subgraph of `adj` formed by the vertices in `v_sub` is a complete graph.
"""
function _check_neighboor_complete(adj::SparseMatrixCSC, v::Int, v_sub::Vector{Int}=1:adj.n)
    neighbors = filter(n -> n in v_sub, _neighbors(adj, v))
    for i in 1:length(neighbors)-1
        for j in i+1:length(neighbors)
            if adj[neighbors[i], neighbors[j]] == 0
                return false
            end
        end
    end
    return true
end


"""
    n = _neighbors(adj, v; exclude)

Return the neighbors of the vertex `v` in `adj` (undirected).
"""
function _neighbors(adj::SparseMatrixCSC, v::Int; exclude=[v])
	return [i for i in 1:adj.n if (adj[v, i] != 0 || adj[i, v] != 0) && i ∉ exclude]
end
