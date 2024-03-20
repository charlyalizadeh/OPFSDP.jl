function build_model(network::PowerFlowNetwork)
    model = Model(Mosek.Optimizer)
    variables = Dict()
    variables["voltages"] = _define_voltage_variable!(model, network)
    merge!(variables, _define_power_variables!(model, network))
    vvm = _get_voltage_variable_map(network, variables["voltages"])
    _define_objective!(model, network, variables)
    _define_power_balance_constraints!(model, network, variables, vvm)
    _define_power_limit_constraints!(model, network, variables)
    _define_voltage_limit_constraints!(model, network, vvm)
    _define_branch_flow_limit_constraints!(model, network, vvm)
    return model
end

function build_model(network::PowerFlowNetwork, cliques, cliquetree)
    model = Model(Mosek.Optimizer)
    variables = _define_clique_variables!(model, network, cliques)
    merge!(variables, _define_power_variables!(model, network))
    vvm = _get_voltage_variable_map(network, cliques, variables)
    _define_objective!(model, network, variables)
    _define_power_balance_constraints!(model, network, variables, vvm)
    _define_power_limit_constraints!(model, network, variables)
    _define_voltage_limit_constraints!(model, network, vvm)
    _define_branch_flow_limit_constraints!(model, network, vvm)
    _define_linking_constraints!(model, variables, cliques, cliquetree)
    check_vvm_integrity(network, variables, vvm, cliques)
    return model
end


function solve!(network::PowerFlowNetwork)
    model = build_model(network)
    optimize!(model)
    return model
end


function solve!(network::PowerFlowNetwork, cliques, cliquetree)
    model = build_model(network, cliques, cliquetree)
    optimize!(model)
	return model
end
