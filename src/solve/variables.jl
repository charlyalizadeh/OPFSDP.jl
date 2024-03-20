function _get_voltage_variable_map(network::PowerFlowNetwork, variable)
    vvm = Dict()
    for (i, bus_id1) in enumerate(network.buses_order)
        for (j, bus_id2) in enumerate(network.buses_order)
            vvm_keys = ["real(v$(bus_id1))*real(v$(bus_id2))",
                        "real(v$(bus_id1))*imag(v$(bus_id2))",
                        "imag(v$(bus_id1))*real(v$(bus_id2))",
                        "imag(v$(bus_id1))*imag(v$(bus_id2))",

                        "real(v$(bus_id2))*real(v$(bus_id1))",
                        "imag(v$(bus_id2))*real(v$(bus_id1))",
                        "imag(v$(bus_id2))*real(v$(bus_id1))",
                        "imag(v$(bus_id2))*imag(v$(bus_id1))"]
            true_i = (i - 1) * 2 + 1
            true_j = (j - 1) * 2 + 1
            for (ikey, key) in enumerate(vvm_keys)
                if !(key in keys(vvm))
                    if ikey % 4 == 1
                        vvm[key] = variable[true_i, true_j]
                    elseif ikey % 4 == 2
                        vvm[key] = variable[true_i, true_j + 1]
                    elseif ikey % 4 == 3
                        vvm[key] = variable[true_i + 1, true_j]
                    elseif ikey % 4 == 0
                        vvm[key] = variable[true_i + 1, true_j + 1]
                    end
                end
            end
        end
    end
    return vvm
end


function _get_voltage_variable_map(network::PowerFlowNetwork, cliques, variables)
    vvm = Dict()
    for (clique_id, clique) in enumerate(cliques)
        for (i, id1) in enumerate(clique)
            for (j, id2) in enumerate(clique)
                bus_id1 = network.buses_order[id1]
                bus_id2 = network.buses_order[id2]
                vvm_keys = ["real(v$(bus_id1))*real(v$(bus_id2))",
                            "real(v$(bus_id1))*imag(v$(bus_id2))",
                            "imag(v$(bus_id1))*real(v$(bus_id2))",
                            "imag(v$(bus_id1))*imag(v$(bus_id2))",

                            "real(v$(bus_id2))*real(v$(bus_id1))",
                            "imag(v$(bus_id2))*real(v$(bus_id1))",
                            "imag(v$(bus_id2))*real(v$(bus_id1))",
                            "imag(v$(bus_id2))*imag(v$(bus_id1))"]
                true_i = (i - 1) * 2 + 1
                true_j = (j - 1) * 2 + 1
                for (ikey, key) in enumerate(vvm_keys)
                    if !(key in keys(vvm))
                        if ikey % 4 == 1
                            vvm[key] = variables["clique_$clique_id"][true_i, true_j]
                        elseif ikey % 4 == 2
                            vvm[key] = variables["clique_$clique_id"][true_i, true_j + 1]
                        elseif ikey % 4 == 3
                            vvm[key] = variables["clique_$clique_id"][true_i + 1, true_j]
                        elseif ikey % 4 == 0
                            vvm[key] = variables["clique_$clique_id"][true_i + 1, true_j + 1]
                        end
                    end
                end
            end
        end
    end
    return vvm
end


function _define_voltage_variable!(model, network)
    nbus = length(network.buses)
    variable = @variable(model, [1:2*nbus, 1:2*nbus], base_name="voltages", PSD)
    return variable
end


function _define_clique_variables!(model, network, cliques)
    clique_variables = Dict()
    for (i, clique) in enumerate(cliques)
        clique_variables["clique_$i"] = @variable(model, [1:2*length(clique), 1:2*length(clique)], base_name="clique_$i", PSD)
    end
    return clique_variables
end


function _define_power_variables!(model, network)
    power_variables = Dict()
    for (id, bus) in network.buses
        power_variables["real(S_$(id))"] = @variable(model, base_name = "real(S_$(id))")
        power_variables["imag(S_$(id))"] = @variable(model, base_name = "imag(S_$(id))")
    end
    return power_variables
end
