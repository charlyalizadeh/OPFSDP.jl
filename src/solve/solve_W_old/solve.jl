function build_model(network)
    model = Model(Mosek.Optimizer)
    Y = admittance_matrix_W(network)

    # Variables
    variables = Dict()
    W = _define_W!(model, network)
    merge!(variables, _define_generator_power_variables!(model, network))

    # Objective
    _define_objective!(model, network, variables; degree=1)

    # Constraints
    constraints = Dict()
    constraints["power_balance"] = _define_power_balance_constraints!(model, network, variables, W, Y)
    constraints["branch_power"] = _define_branch_power_limit_constraints!(model, network, variables, W, Y)
    constraints["voltage_angle"] = _define_voltage_angle_limit_constraints!(model, network, variables, W)
    constraints["voltage_reference"] = _define_voltage_reference_constraints!(model, network, variables, W)
    constraints["voltage_module"] = _define_voltage_limit_constraints!(model, network, variables, W)

    variables["W"] = W
    return model, variables, constraints
end



function solve(network)
    if !hasgencost(network)
        println("Cannot solve network $(network.name). No cost found.")
        return nothing, nothing, nothing
    end
    build_time = @elapsed ((model, variables, constraints) = build_model(network))
    println("Building time: $build_time (s)")
    optimize!(model)
    return model, variables, constraints
end
