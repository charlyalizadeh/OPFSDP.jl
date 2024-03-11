# Source: https://github.com/lanl-ansi/PowerModels.jl/blob/master/src/form/wrm.jl
function maximal_cliquetree(cliques)
	cliquegraph = _overlap_graph(cliques)
	return _prim(cliquegraph)
end


"""
    A = _overlap_graph(groups)
Return adjacency matrix for overlap graph associated with `groups`.
I.e. if `A[i, j] = k`, then `groups[i]` and `groups[j]` share `k` elements.
"""
function _overlap_graph(groups)
    n = length(groups)
    I = Vector{Int}()
    J = Vector{Int}()
    V = Vector{Int}()
    for (i, gi) in enumerate(groups)
        for (j, gj) in enumerate(groups)
            if gi != gj
                overlap = length(intersect(gi, gj))
                if overlap > 0
                    push!(I, i)
                    push!(J, j)
                    push!(V, overlap)
                end
            end
        end
    end
    return sparse(I, J, V, n, n)
end


function _filter_flipped_pairs!(pairs)
    for (i, j) in pairs
        if i != j && (j, i) in pairs
            filter!(x -> x != (j, i), pairs)
        end
    end
end


"""
    idx_a, idx_b = _overlap_indices(A, B)
Given two arrays (sizes need not match) that share some values, return:

- linear index of shared values in A
- linear index of shared values in B

Thus, A[idx_a] == B[idx_b].
"""
function _overlap_indices(A::Array, B::Array, symmetric=true)
    overlap = intersect(A, B)
    symmetric && _filter_flipped_pairs!(overlap)
    idx_a = [something(findfirst(isequal(o), A), 0) for o in overlap]
    idx_b = [something(findfirst(isequal(o), B), 0) for o in overlap]
    return idx_a, idx_b
end


"""
    T = _prim(A, minweight=false)
Return minimum spanning tree adjacency matrix, given adjacency matrix.
If minweight == false, return the *maximum* weight spanning tree.

Convention: start with node 1.
"""
function _prim(A, minweight=false)
    n = size(A, 1)
    candidate_edges = []
    unvisited = collect(1:n)
    next_node = 1 # convention
    T = spzeros(Int, n, n)

    while length(unvisited) > 1
        current_node = next_node
        filter!(node -> node != current_node, unvisited)

        neighbors = intersect(findall(x->x!=0, A[:, current_node]), unvisited)
        current_node_edges = [(current_node, i) for i in neighbors]
        append!(candidate_edges, current_node_edges)
        filter!(edge -> length(intersect(edge, unvisited)) == 1, candidate_edges)
        weights = [A[edge...] for edge in candidate_edges]
        next_edge = minweight ? candidate_edges[indmin(weights)] : candidate_edges[argmax(weights)]
        filter!(edge -> edge != next_edge, candidate_edges)
        T[next_edge...] = minweight ? minimum(weights) : maximum(weights)
        next_node = intersect(next_edge, unvisited)[1]
    end
    return T
end
