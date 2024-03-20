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
