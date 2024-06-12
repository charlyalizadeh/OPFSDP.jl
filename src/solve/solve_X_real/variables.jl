function _define_X!(model, network)
    @variable(model, [1:2*nbus(network), 1:2*nbus(network)], PSD)
end

function _define_cliques!(model, network, cliques)
    variables = Dict()
    for (i, clique) in enumerate(cliques)
        variables["X$i"] = @variable(model, [1:2*length(clique), 1:2*length(clique)], base_name="X$i", PSD)
    end
    return variables
end

function _map_X!(model, network, cliques, variables)
    X = Dict()
    for (clique_id, clique) in enumerate(cliques)
        clength = length(clique)
        for (i, b) in enumerate(clique)
            for (j, a) in enumerate(clique)
                if a == b
                    X["vr($b)vr($b)"] = variables["X$clique_id"][i, i]
                    X["vc($b)vc($b)"] = variables["X$clique_id"][clength + i, clength + i]
                    X["vr($b)vc($b)"] = variables["X$clique_id"][i, clength + i]
                    X["vc($b)vr($b)"] = variables["X$clique_id"][i, clength + i]
                else
                    if (b == 1 && a == 2) || (b == 2 && a == 1)
                        println("i = $i j = $j clength = $clength")
                    end
                    X["vr($b)vr($a)"] = variables["X$clique_id"][i, j]
                    X["vr($a)vr($b)"] = variables["X$clique_id"][i, j]

                    X["vc($b)vc($a)"] = variables["X$clique_id"][clength + i, clength + j]
                    X["vc($a)vc($b)"] = variables["X$clique_id"][clength + i, clength + j]

                    X["vr($b)vc($a)"] = variables["X$clique_id"][i, clength + j]
                    X["vc($a)vr($b)"] = variables["X$clique_id"][i, clength + j]

                    X["vc($b)vr($a)"] = variables["X$clique_id"][clength + i, j]
                    X["vr($a)vc($b)"] = variables["X$clique_id"][clength + i, j]
                end
            end
        end
    end
    return X
end

function _define_generator_power_variables!(model, network)
    variables = Dict()
    for gen in generators(network)
        variables["real(S_$(gen.genid))"] = @variable(model, base_name = "real(S_$(gen.genid))")
        variables["imag(S_$(gen.genid))"] = @variable(model, base_name = "imag(S_$(gen.genid))")
        !isinf(gen.Pmax) && set_upper_bound(variables["real(S_$(gen.genid))"], gen.Pmax)
		!isinf(gen.Pmin) && set_lower_bound(variables["real(S_$(gen.genid))"], gen.Pmin)
		!isinf(gen.Qmax) && set_upper_bound(variables["imag(S_$(gen.genid))"], gen.Qmax)
		!isinf(gen.Qmin) && set_lower_bound(variables["imag(S_$(gen.genid))"], gen.Qmin)
    end
    return variables
end

function _define_abs2_variables!(model, network, X)
    variables = Dict()
    for bus in buses(network)
        b = normid(network, bus.id)
        variables["|v($b)|^2"] = @expression(model, X["vr($b)vr($b)"] + X["vc($b)vc($b)"])
    end
    return variables
end

function _define_flow_variables!(model, network)
    variables = Dict()
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        # L0
        variables["real(S_$(b)_$(a))"] = @variable(model, base_name = "real(S_$(b)_$(a))")
        variables["imag(S_$(b)_$(a))"] = @variable(model, base_name = "imag(S_$(b)_$(a))")
        # L1
        variables["real(S_$(a)_$(b))"] = @variable(model, base_name = "real(S_$(a)_$(b))")
        variables["imag(S_$(a)_$(b))"] = @variable(model, base_name = "imag(S_$(a)_$(b))")
    end
    return variables
end
