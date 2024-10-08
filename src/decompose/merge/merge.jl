abstract type AbstractMerge end
mutable struct MolzahnMerge <: AbstractMerge
    L::Float64
    MolzahnMerge(L::Float64=0.1) = new(L)
end

# TODO: compute the merge cost only once and then update them in function the cliques merged
"""
    cost = compute_merge_cost(c1, c2)

Return the cost of merging the clique `c1` and `c2`.
"""
function compute_merge_cost(c1::Vector{Int}, c2::Vector{Int})
    di = length(c1)
    dk = length(c2)
    sik = length(intersect(c1, c2))
    dik = di + dk - sik
    delta_ik = dik * (2 * dik + 1) - di * (2 * di + 1) - dk * (2 * dk + 1) - sik * (2 * sik + 1)
    return delta_ik
end


"""
    costs = compute_merge_cost_all(maximal_cliques, clique_tree)

Return the merge cost array of all the edges in `clique_tree`.
"""
function compute_merge_cost_all(maximal_cliques, clique_tree)
    costs = []
    for i in 1:clique_tree.n-1
        for k in i+1:clique_tree.n
            if clique_tree[i, k] != 0
                push!(costs, [i, k, compute_merge_cost(maximal_cliques[i], maximal_cliques[k])])
            end
        end
    end
    return costs
end


"""
    clique_tree = merge_clique!(i, k, maximal_cliques, clique_tree)

Merge the cliques `maximal_cliques[i]` and `maximal_cliques[k]`.
Modify `maximal_cliques` by deleting the cliques at index `i` and `k` and adding the new cliques formed by their merge.
Return the modified clique_tree where the cliques at index `i` and `k` are merged.
"""
function merge_clique!(i, k, clique, maximal_cliques, clique_tree)
    _neighbors = union(neighbors(clique_tree, i; exclude=[i, k]), neighbors(clique_tree, k; exclude=[i, k]))
    _neighbors = map(n -> n - (n > i) - (n > k), _neighbors)

    deleteat!(maximal_cliques, [i, k])
    push!(maximal_cliques, clique)
    # not a fan of using unicode char, but couldn't find the corresponding ascii char for ∉
    # cannot modify a matrix in place in Julia ? So I have to return it instead
    clique_tree = clique_tree[1:clique_tree.n .∉ [[i, k]], 1:clique_tree.n .∉ [[i, k]]]
    clique_tree = [clique_tree; zeros(clique_tree.n)']
    clique_tree = [clique_tree zeros(clique_tree.m)]
    for n in _neighbors
        weight = length(intersect(maximal_cliques[n], maximal_cliques[end]))
        clique_tree[n, end] = weight
        clique_tree[end, n] = weight
    end
    return clique_tree
end


"""
    merge_molzahn!(cadj, maximal_cliques, clique_tree, L=0.1)

Apply the Molzahn et al. merging alogrithm to the chordal graph represented by `cadj`.
`L` is a percentage of the number of cliques in `maximal_cliques`. It is used to stop the merging.
"""
function merge_molzahn!(cadj, maximal_cliques, clique_tree, L::Float64=0.1)
    total_cost = 0
    treshold = L * length(maximal_cliques)
    if treshold < 2
        treshold = 2
    end
    while length(maximal_cliques) > treshold
        costs = compute_merge_cost_all(maximal_cliques, clique_tree)
        i, k, cost = argmin(x -> x[3], costs)
        total_cost += -cost
        clique = union(maximal_cliques[i], maximal_cliques[k])
        clique_tree = merge_clique!(i, k, clique, maximal_cliques, clique_tree)
    end
    for c in maximal_cliques
        make_subgraph_complete!(cadj, c)
    end
    println("TOTAL REWARD: $(total_cost)")
end
merge_cliques!(cadj, maximal_cliques, clique_tree, merge_alg::MolzahnMerge) = merge_molzahn!(cadj, maximal_cliques, clique_tree, merge_alg.L)
