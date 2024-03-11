function solve!(network::PowerFlowNetwork, cliques, cliquetree)
    model = Model(Mosek.Optimizer)
    ##@info "Solving $(network.name)"
    #@info "    Number of cliques: $(length(cliques))"
    #@info "    Number of edges in the cliquetree: $(length(edges(cliquetree)))"

    #@info "    Defining variables"
    #@info "        Defining cliques"
    variables = _define_clique_variables!(model, network, cliques)
    #@info "        Defining power variables"
    merge!(variables, _define_power_variables!(model, network))
    #@info "        Mapping the voltage to the cliques"
    vvm = _get_voltage_variable_map(network, cliques, variables)

    #@info "    Defining the objective function"
    _define_objective!(model, network, variables)

    #@info "    Defining the the constraints"
    #@info "        Power balance"
    _define_power_balance_constraints!(model, network, variables, vvm)
    #@info "        Power limits"
    _define_power_limit_constraints!(model, network, variables)
    #@info "        Voltage limits"
    _define_voltage_limit_constraints!(model, network, vvm)
    #@info "        Branch flow limits"
    _define_branch_flow_limit_constraints!(model, network, vvm)
    #@info "        Linking constraints"
    _define_linking_constraints!(model, variables, cliques, cliquetree)

    #@info "    Checking the integrity of the voltage map"
    _check_vvm_integrity(network, variables, vvm, cliques)

    #@info "    Optimizing the model"
    optimize!(model)
	return model
end
