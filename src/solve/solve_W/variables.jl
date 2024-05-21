function _define_W!(model, network)
    return @variable(model, [1:2*nbus(network), 1:2*nbus(network)], base_name="W", PSD)
end


function _define_cliques!(model, network, cliques)
    variables = Dict()
    for (i, clique) in enumerate(cliques)
        variables["W$i"] = @variable(model, [1:2*length(clique), 1:2*length(clique)], base_name = "W$i", PSD)
    end
    return variables
end

function _map_W(model, network, cliques, variables)
    W = Dict()
    _nbus = nbus(network)
    for (clique_id, clique) in enumerate(cliques)
        for (i, b) in enumerate(clique)
            for (j, a) in enumerate(clique)
                W["$b, $a"] = variables["W$clique_id"][i, j]
                W["$(_nbus + b), $a"] = variables["W$clique_id"][length(clique) + i, j]
                W["$b, $(_nbus + a)"] = variables["W$clique_id"][i, length(clique) + j]
                W["$(_nbus + b), $(_nbus + a)"] = variables["W$clique_id"][length(clique) + i, length(clique) + j]
            end
        end
    end
    return DefaultDict(0, W)
end


function _define_generator_power_variables!(model, network)
    variables = Dict()
    for gen in generators(network)
        variables["S_$(gen.genid)"] = @variable(model, set = ComplexPlane(), base_name = "S_$(gen.genid)")
        set_start_value(real(variables["S_$(gen.genid)"]), real(gen.power))
        set_start_value(imag(variables["S_$(gen.genid)"]), imag(gen.power))
        !isinf(gen.Pmax) && set_upper_bound(real(variables["S_$(gen.genid)"]), gen.Pmax)
		!isinf(gen.Pmin) && set_lower_bound(real(variables["S_$(gen.genid)"]), gen.Pmin)
		!isinf(gen.Qmax) && set_upper_bound(imag(variables["S_$(gen.genid)"]), gen.Qmax)
		!isinf(gen.Qmin) && set_lower_bound(imag(variables["S_$(gen.genid)"]), gen.Qmin)
    end
    return variables
end

function _map_W_array(model, network, cliques, variables)
    W = Dict()
    _nbus = nbus(network)
    for (clique_id, clique) in enumerate(cliques)
        for (i, b) in enumerate(clique)
            for (j, a) in enumerate(clique)
                if !("$b, $a" in keys(W))
                    W["$b, $a"] = []
                end
                if !("$(_nbus + b), $(_nbus + a)" in keys(W))
                    W["$(_nbus + b), $(_nbus + a)"] = []
                end
                if !("$(_nbus + b), $a" in keys(W))
                    W["$(_nbus + b), $a" ] = []
                end
                if !("$b, $(_nbus + a)" in keys(W))
                    W["$b, $(_nbus + a)"] = []
                end
                push!(W["$b, $a"], variables["W$clique_id"][i, j])
                push!(W["$(_nbus + b), $a"], variables["W$clique_id"][length(clique) + i, j])
                push!(W["$b, $(_nbus + a)"], variables["W$clique_id"][i, length(clique) + j])
                push!(W["$(_nbus + b), $(_nbus + a)"], variables["W$clique_id"][length(clique) + i, length(clique) + j])
            end
        end
    end
    return DefaultDict(0, W)
end
