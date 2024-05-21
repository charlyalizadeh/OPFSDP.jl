#function build_model(network; pb_path=nothing)
#    model = Model(Mosek.Optimizer)
#    Y = admittance_matrix(network)
#
#    # Variables
#    variables = Dict()
#    W = _define_W!(model, network)
#    merge!(variables, _define_generator_power_variables!(model, network))
#
#    # Objective
#    _define_objective!(model, network, variables)
#
#    # Constraints
#    constraints = Dict()
#    if isnothing(pb_path)
#        constraints["power_balance"] = _define_power_balance_constraints!(model, network, variables, W, Y)
#    else
#        constraints["power_balance"] = load_power_balance_constraints!(model, network, W, variables, pb_path)
#    end
#    constraints["branch_power"] = _define_branch_power_limit_constraints!(model, network, variables, W, Y)
#    constraints["voltage_angle"] = _define_voltage_angle_limit_constraints!(model, network, variables, W)
#    constraints["voltage_reference"] = _define_voltage_reference_constraints!(model, network, variables, W)
#    constraints["voltage_module"] = _define_voltage_limit_constraints!(model, network, variables, W)
#
#    variables["W"] = W
#    return model, variables, constraints
#end
#
#
#function build_model(network, cliques, cliquetree; pb_path=nothing)
#    model = Model(Mosek.Optimizer)
#    Y = admittance_matrix(network)
#
#    # Variables
#    variables = _define_cliques!(model, network, cliques)
#    merge!(variables, _define_generator_power_variables!(model, network))
#    W = _map_W!(model, network, cliques, variables)
#
#    # Objective
#    _define_objective!(model, network, variables)
#
#    # Constraints
#    constraints = Dict()
#    if isnothing(pb_path)
#        constraints["power_balance"] = _define_power_balance_constraints!(model, network, variables, W, Y)
#    else
#        constraints["power_balance"] = load_power_balance_constraints!(model, network, W, variables, pb_path)
#    end
#    constraints["branch_power"] = _define_branch_power_limit_constraints!(model, network, variables, W, Y)
#    constraints["voltage_angle"] = _define_voltage_angle_limit_constraints!(model, network, variables, W)
#    constraints["voltage_reference"] = _define_voltage_reference_constraints!(model, network, variables, W)
#    constraints["voltage_module"] = _define_voltage_limit_constraints!(model, network, variables, W)
#    constraints["linking_constraints"] = _define_linking_constraints!(model, variables, cliques, cliquetree)
#
#    variables["W"] = W
#    return model, variables, constraints
#end
#
#
#function solve(network; pb_path=nothing)
#    build_time = @elapsed ((model, variables, constraints) = build_model(network; pb_path=pb_path))
#    println("Building time: $build_time (s)")
#    optimize!(model)
#    return model, variables, constraints
#end
#
#
#function solve(network, cliques, cliquetree; pb_path=nothing)
#    build_time = @elapsed ((model, variables, constraints) = build_model(network, cliques, cliquetree; pb_path=pb_path))
#    println("Building time: $build_time (s)")
#    optimize!(model)
#    return model, variables, constraints
#end
