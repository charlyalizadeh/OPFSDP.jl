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


function _prim(A)
    n = A.n
    E = -1 * ones(Int, n)
    F = spzeros(Int, n, n)
    Q = PriorityQueue(Base.Order.Reverse)
    for v in 1:n
        enqueue!(Q, v, -100000)
    end
    while !isempty(Q)
        v = dequeue!(Q)
        for w in neighbors(A, v)
            if w in keys(Q) && A[v, w] > Q[w]
                Q[w] = A[v, w]
                E[w] = v
            end
        end
    end
    for v in 1:n
        if E[v] == -1 || F[v, E[v]] != 0
            continue
        end
        F[v, E[v]] = A[v, E[v]]
        F[E[v], v] = A[v, E[v]]
    end
    return F
end
