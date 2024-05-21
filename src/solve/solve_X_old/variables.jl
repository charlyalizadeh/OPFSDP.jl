function _define_cliques!(model, network, cliques)
    variables = Dict()
    for (i, clique) in enumerate(cliques)
        variables["X$i"] = @variable(model, [1:length(clique), 1:length(clique)] in HermitianPSDCone(), base_name = "X$i")
    end
    return variables
end

function _map_X!(model, network, cliques, variables)
    X = Dict()
    for (clique_id, clique) in enumerate(cliques)
        for (i, b) in enumerate(clique)
            for (j, a) in enumerate(clique)
                X["$b, $a"] = variables["X$clique_id"][i, j]
            end
        end
    end
    return X
end

function _define_generator_power_variables!(model, network)
    power_variables = Dict()
    for gen in generators(network)
        power_variables["S_$(gen.genid)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(gen.genid)")
    end
    return power_variables
end


function _define_flow_variables!(model, network)
    flow_variables = Dict()
    for branch in branches(network)
        nidfrom = normid(network, branch.from)
        nidto = normid(network, branch.to)
        flow_variables["S_$(nidfrom)_$(nidto)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(nidfrom)_$(nidto)")
        flow_variables["S_$(nidto)_$(nidfrom)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(nidto)_$(nidfrom)")
    end
    return flow_variables
end
