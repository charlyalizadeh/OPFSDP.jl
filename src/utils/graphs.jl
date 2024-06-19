function adjacency_matrix(network::PowerFlowNetwork)
	adj = zeros(length(network.buses_order), length(network.buses_order))
    order_map = Dict(v => i for (i, v) in enumerate(network.buses_order))
	for branch in network.branches
        bus_index1 = order_map[branch.from]
        bus_index2 = order_map[branch.to]
		adj[bus_index1, bus_index2] = 1.0
		adj[bus_index2, bus_index1] = 1.0
	end
	return sparse(adj)
end

function edges(adj::SparseMatrixCSC)
	edges_list = []
	for i in 1:adj.n-1
		for j in i+1:adj.n
			if adj[i, j] != 0 || adj[j, i] != 0
				push!(edges_list, [i, j])
			end
		end
	end
	return edges_list
end

function nedge(adj::SparseMatrixCSC)
    nedge = 0
	for i in 1:adj.n-1
		for j in i+1:adj.n
			if adj[i, j] != 0 || adj[j, i] != 0
				nedge += 1
			end
		end
	end
	return nedge
end

"""
    peo = mcs(A)
Maximum cardinality search for graph adjacency matrix A.
Returns a perfect elimination ordering for chordal graphs.
"""
function mcs(A)
    n = size(A, 1)
    w = zeros(Int, n)
    peo = zeros(Int, n)
    unnumbered = collect(1:n)

    for i = n:-1:1
        z = unnumbered[argmax(w[unnumbered])]
        filter!(x -> x != z, unnumbered)
        peo[i] = z

        Nz = findall(x->x!=0, A[:, z])
        for y in intersect(Nz, unnumbered)
            w[y] += 1
        end
    end
    return peo
end

"""
    T = prim(A)
Return minimum spanning tree adjacency matrix, given adjacency matrix.
If minweight == false, return the *maximum* weight spanning tree.

Convention: start with node 1.
"""
function prim(A)
    n = size(A, 1)
    candidate_edges = []
    unvisited = collect(1:n)
    next_node = 1 # convention
    T = spzeros(Int, n, n)

    while length(unvisited) > 1
        current_node = next_node
        filter!(node -> node != current_node, unvisited)
        _neighbors = intersect(findall(x->x!=0, A[:, current_node]), unvisited)
        current_node_edges = [(current_node, i) for i in _neighbors]
        append!(candidate_edges, current_node_edges)
        filter!(edge -> length(intersect(edge, unvisited)) == 1, candidate_edges)
        weights = [A[edge...] for edge in candidate_edges]
        next_edge = candidate_edges[argmax(weights)]
        filter!(edge -> edge != next_edge, candidate_edges)
        weight = maximum(weights)
        T[next_edge[1], next_edge[2]] = weight
        T[next_edge[2], next_edge[1]] = weight
        next_node = intersect(next_edge, unvisited)[1]
    end
    return T
end

"""
    A = overlap_graph(groups)
Return adjacency matrix for overlap graph associated with `groups`.
I.e. if `A[i, j] = k`, then `groups[i]` and `groups[j]` share `k` elements.
"""
function overlap_graph(groups)
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

"""
    n = neighbors(adj, v; exclude)

Return the neighbors of the vertex `v` in `adj` (undirected).
"""
function neighbors(adj::SparseMatrixCSC, v::Int; exclude=[v])
	return [i for i in 1:adj.n if (adj[v, i] != 0 || adj[i, v] != 0) && i ∉ exclude]
end

function check_complete(adj::SparseMatrixCSC)
    nedge(adj) == ((adj.n) * (adj.n - 1)) / 2
end

"""
    is_complete = check_neighboor_complete(adj, v, v_sub)

Return `true` if the neighbors of `v` in the subgraph of `adj` formed by the vertices in `v_sub` is a complete graph.
"""
function check_neighboor_complete(adj::SparseMatrixCSC, v::Int, v_sub::Vector{Int}=1:adj.n)
    _neighbors = filter(n -> n in v_sub, neighbors(adj, v))
    for i in 1:length(_neighbors)-1
        for j in i+1:length(_neighbors)
            if adj[_neighbors[i], _neighbors[j]] == 0
                return false
            end
        end
    end
    return true
end

"""
    is_chordal = check_chordal(adj)

Return `true` if the adjacency matrix `adj` corresponds to a chordal graph.
"""
function check_chordal(adj::SparseMatrixCSC)
    peo = mcs(adj)
    for i in 1:length(peo)-1
        if !check_neighboor_complete(adj, peo[i], peo[i:end])
            return false
        end
    end
    return true
end


"""
    make_neighborhood_complete!(adj, v)

Make the neighborhood of `v` complete in `adj`.
"""
function make_neighborhood_complete!(adj::SparseMatrixCSC, v::Int)
    _neighbors = neighbors(adj, v)
    for i in 1:length(_neighbors) - 1
        for j in i+1:length(_neighbors)
            adj[_neighbors[i], _neighbors[j]] = 1.0
            adj[_neighbors[j], _neighbors[i]] = 1.0
        end
    end
end


"""
    pmdo = perfect_minimum_degree_ordering(adj)

Return a perfect minimum degree ordering of the graph represented by `adj`.
"""
function perfect_minimum_degree_ordering(adj::SparseMatrixCSC)
    vertex_map = 1:adj.n
    perm = Int[]
    for i in 1:adj.n
        vmindeg = argmin([sum(adj[1:end, j]) for j in 1:adj.n])
        push!(perm, vertex_map[vmindeg])
        make_neighborhood_complete!(adj, vmindeg)
        vertex_map = [vertex_map[vmindeg] <= vertex_map[j] ? vertex_map[j + 1] : vertex_map[j] for j in 1:adj.n - 1]
        adj = adj[1:end .!= vmindeg, 1:end .!= vmindeg]
    end
    return perm
end

"""
    make_subgraph_complete!(adj, vertices)

Make the subgraph of `adj` composed of the vertices in `vertices` complete.
"""
function make_subgraph_complete!(adj::SparseMatrixCSC, vertices::Vector{Int})
    for i in 1:length(vertices)-1
        for j in i+1:length(vertices)
            adj[vertices[i], vertices[j]] = 1.0
            adj[vertices[j], vertices[i]] = 1.0
        end
    end
end


function get_edges_under_dist(adj::SparseMatrixCSC, source::Int, max_dist::Int)
    dist = ones(adj.n) * Inf
    current_vertices = [source]
    vertices = []
    for i in 1:max_dist
        next_vertices = []
        for v in current_vertices
            for b in neighbors(adj, v)
                if !(b in vertices) && b != source
                    push!(vertices, b)
                    push!(next_vertices, b)
                end
            end
        end
        current_vertices = next_vertices
    end
    return vertices
end

function add_random_edge!(adj::SparseMatrixCSC, nb_edge::Int, max_dist::Int=3, max_stable_it::Int=5)
    nedge_adj = nedge(adj)
    nedge_max = (adj.n * (adj.n - 1)) / 2
    stable_it = 0
    while nb_edge > 0 && nedge_adj != nedge_max && stable_it < max_stable_it
        v1 = rand(1:adj.n)
        edges_choice = get_edges_under_dist(adj, v1, max_dist)
        v2 = edges_choice[rand(1:length(edges_choice))]
        if adj[v1, v2] == 1
            stable_it += 1
            continue
        end
        stable_it = 0
        adj[v1, v2] = 1
        adj[v2, v1] = 1
        nedge_adj += 1
        nb_edge -= 1
    end
end

function add_random_edge_vertex!(adj::SparseMatrixCSC, nb_edge::Float64, max_dist::Int=3, max_stable_it::Int=5)
    nb_edge_int = trunc(Int, nb_edge * adj.n)
    add_random_edge!(adj, nb_edge_int, max_dist, max_stable_it)
end

function add_random_edge_edge!(adj::SparseMatrixCSC, nb_edge::Float64, max_dist::Int=3, max_stable_it::Int=5)
    nb_edge_int = trunc(Int, nb_edge * nedge(adj))
    add_random_edge!(adj, nb_edge_int, max_dist, max_stable_it)
end
