function _define_linking_constraints!(model, variables, cliques, cliquetree)
	for e in edges(cliquetree)
		buses_indexes = intersect(cliques[e[1]], cliques[e[2]])
		for (i, bid1) in enumerate(buses_indexes)
			for (j, bid2) in enumerate(buses_indexes[i:end])
                imat1_1 = findfirst(==(bid1), cliques[e[1]])
                imat1_2 = findfirst(==(bid2), cliques[e[1]])
                imat2_1 = findfirst(==(bid1), cliques[e[2]])
                imat2_2 = findfirst(==(bid2), cliques[e[2]])
                # Re(bus1) * Re(bus2)
                @constraint(model, variables["clique_$(e[1])"][imat1_1, imat1_2] == variables["clique_$(e[2])"][imat2_1, imat2_2])
                # Re(bus1) * Im(bus2)
                @constraint(model, variables["clique_$(e[1])"][imat1_1, imat1_2 + 1] == variables["clique_$(e[2])"][imat2_1, imat2_2 + 1])
                # Im(bus1) * Re(bus2)
                @constraint(model, variables["clique_$(e[1])"][imat1_1 + 1, imat1_2] == variables["clique_$(e[2])"][imat2_1 + 1, imat2_2 ])
                # Im(bus1) * Im(bus2)
                @constraint(model, variables["clique_$(e[1])"][imat1_1 + 1, imat1_2 + 1] == variables["clique_$(e[2])"][imat2_1 + 1, imat2_2 + 1])
			end
		end
	end
end
