function _get_voltage_variable_map(network, cliques, variables)
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


function _display_matrices(network, variables, vvm, cliques)
    for (id_clique, clique) in enumerate(cliques)
        println("CLIQUES $(id_clique)")
        clique_complex = []
        for bus in clique
            append!(clique_complex, ["real(v$(network.buses[bus].id))", "imag(v$(network.buses[bus].id))"])
        end
        println(clique_complex)
        for val1 in clique_complex
            for val2 in clique_complex
                print("$(vvm["$(val1)*$(val2)"]) ")
            end
            println()
        end
        println()
    end
end

function _extract_vvm_bus_id(key)
    _, id1, id2 = split(replace(key, "v" => "", "*" => "", "real(" => ",", "imag(" => ",", ")" => ""), ',')
    return (id1, id2)
end

function _extract_variable_bus_id(variable)
    v_str = string(variable)
    clique_id = parse(Int, split(replace(v_str, "clique_" => "", "[" => ",", "]" => ","), ',')[1])
    i, j = split(replace(v_str, "clique_$(clique_id)" => "", "]" => "", "[" => ""), ',')
    i = parse(Int, i)
    j = parse(Int, j)
    return (clique_id, i, j)
end

function _check_vvm_integrity(network, variables, vvm, cliques)
    for (key, variable) in vvm
        id1, id2 = _extract_vvm_bus_id(key)
        clique_id, i, j = _extract_variable_bus_id(variable)
        clique_complex = []
        for bus_index in cliques[clique_id]
            bus_id = network.buses_order[bus_index]
            append!(clique_complex, ["real(v$(bus_id))", "imag(v$(bus_id))"])
        end
        key2 =  join(sort(["$(clique_complex[i])", "$(clique_complex[j])"]), "*")
        key = join(sort(split(key, '*')), "*")
        if key != key2
            println("ERROR: $(key) != $(key2)")
        end
    end
end
