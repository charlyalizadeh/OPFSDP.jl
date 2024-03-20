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


function check_vvm_integrity(network, variables, vvm, cliques)
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
            error("Variable voltage map not correctly defined: $(key) != $(key2)")
        end
    end
end



function check_power_balance_equation(network)
    for (id, bus) in network.buses
        branches_out = get_branches_out(network, bus.id)
        branches_in = get_branches_in(network, bus.id)
        power = bus.load
        if !isempty(branches_out)
            power += sum(_branch_compute_power_origin_1(branch)*abs2(bus.v) +
                         _branch_compute_power_origin_2(branch)*bus.v*conj(network.buses[branch.dst].v)
                         for branch in branches_out)
        end
        if !isempty(branches_in)
            power += sum(_branch_compute_power_destination_1(branch)*abs2(bus.v) +
                         _branch_compute_power_destination_2(branch)*bus.v*conj(network.buses[branch.src].v)
                         for branch in branches_in)
        end
        @printf "S_%d = %.4f %+.4fi" bus.id real(power) imag(power)
        if bus.id in keys(network.generators)
            gen_power = network.generators[bus.id][1].power
            @printf " = %.4f %+.4fi" real(gen_power) imag(gen_power)
        end
        println()
    end
end

