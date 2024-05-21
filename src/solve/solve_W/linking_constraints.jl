function _link_cliques!(model, variables, cliques, edge)
    constraints = []
    intersect_values = intersect(cliques[edge[1]], cliques[edge[2]])
    l1 = length(cliques[edge[1]])
    l2 = length(cliques[edge[2]])
    for (i, value1) in enumerate(intersect_values)
        for value2 in intersect_values[i:end]
            id1v1 = findfirst(==(value1), cliques[edge[1]])
            id1v2 = findfirst(==(value2), cliques[edge[1]])
            id2v1 = findfirst(==(value1), cliques[edge[2]])
            id2v2 = findfirst(==(value2), cliques[edge[2]])
            push!(constraints, @constraint(model, variables["W$(edge[1])"][id1v1, id1v2] == variables["W$(edge[2])"][id2v1, id2v2]))
            push!(constraints, @constraint(model, variables["W$(edge[1])"][id1v1, l1 + id1v2] == variables["W$(edge[2])"][id2v1, l2 + id2v2]))
            push!(constraints, @constraint(model, variables["W$(edge[1])"][l1 + id1v1, id1v2] == variables["W$(edge[2])"][l2 + id2v1, id2v2]))
            push!(constraints, @constraint(model, variables["W$(edge[1])"][l1 + id1v1, l1 + id1v2] == variables["W$(edge[2])"][l2 + id2v1, l2 + id2v2]))
        end
    end
    return constraints
end

function _define_linking_constraints!(model, variables, cliques, cliquetree; linking_edges = nothing)
    constraints = []
    _edges = isnothing(linking_edges) ? edges(cliquetree) : linking_edges
    for edge in _edges
        append!(constraints, _link_cliques!(model, variables, cliques, edge))
    end
    return Dict("linking_constraints" => constraints)
end
