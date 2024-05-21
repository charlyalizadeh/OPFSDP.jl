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
    variables = Dict()
    for gen in generators(network)
        variables["S_$(gen.genid)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(gen.genid)")
        !isinf(gen.Pmax) && set_upper_bound(real(variables["S_$(gen.genid)"]), gen.Pmax)
		!isinf(gen.Pmin) && set_lower_bound(real(variables["S_$(gen.genid)"]), gen.Pmin)
		!isinf(gen.Qmax) && set_upper_bound(imag(variables["S_$(gen.genid)"]), gen.Qmax)
		!isinf(gen.Qmin) && set_lower_bound(imag(variables["S_$(gen.genid)"]), gen.Qmin)
    end
    return variables
end


function _define_flow_variables!(model, network)
    variables = Dict()
    for branch in branches(network)
        nidfrom = normid(network, branch.from)
        nidto = normid(network, branch.to)
        variables["S_$(nidfrom)_$(nidto)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(nidfrom)_$(nidto)")
        variables["S_$(nidto)_$(nidfrom)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(nidto)_$(nidfrom)")
        if branch.rateA != 0 && !isinf(branch.rateA)
            set_upper_bound(real(variables["S_$(nidfrom)_$(nidto)"]), branch.rateA)
            set_upper_bound(imag(variables["S_$(nidfrom)_$(nidto)"]), branch.rateA)
            set_lower_bound(real(variables["S_$(nidfrom)_$(nidto)"]), -branch.rateA)
            set_lower_bound(imag(variables["S_$(nidfrom)_$(nidto)"]), -branch.rateA)
        end
    end
    return variables
end
