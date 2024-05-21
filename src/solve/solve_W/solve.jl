function _build_model(network; pb_path=nothing)
    model = Model(Mosek.Optimizer)
    Y = admittance_matrix_W(network)

    # Variables
    variables = Dict()
    W = _define_W!(model, network)
    merge!(variables, _define_generator_power_variables!(model, network))

    # Objective
    _define_objective!(model, network, variables; degree=2)

    # Constraints
    constraints = Dict()
    if isnothing(pb_path)
        constraints["power_balance"] = _define_power_balance_constraints!(model, network, variables, W, Y)
    else
        constraints["power_balance"] = load_power_balance_constraints!(model, network, W, variables, pb_path)
    end
    constraints["branch_power"] = _define_branch_power_limit_constraints!(model, network, variables, W, Y)
    constraints["voltage_angle"] = _define_voltage_angle_limit_constraints!(model, network, variables, W)
    constraints["voltage_reference"] = _define_voltage_reference_constraints!(model, network, variables, W)
    constraints["voltage_module"] = _define_voltage_limit_constraints!(model, network, variables, W)

    variables["W"] = W
    return model, variables, constraints
end


function _build_model_dec(network, cliques, cliquetree; pb_path=nothing, linking_edges=nothing)
    model = Model(Mosek.Optimizer)
    Y = admittance_matrix_W(network)

    # Variables
    println("Defining cliques")
    variables = _define_cliques!(model, network, cliques)
    println("Defining power variables")
    merge!(variables, _define_generator_power_variables!(model, network))
    println("Mapping W")
    W = _map_W(model, network, cliques, variables)

    # Objective
    println("Defining objective")
    _define_objective!(model, network, variables)

    # Constraints
    constraints = Dict()
    if isnothing(pb_path)
        println("Defining power balance")
        constraints["power_balance"] = _define_power_balance_constraints!(model, network, variables, W, Y)
    else
        println("Loading power balance")
        constraints["power_balance"] = load_power_balance_constraints!(model, network, W, variables, pb_path)
    end
    println("Constraints")
    println("   Branch power")
    constraints["branch_power"] = _define_branch_power_limit_constraints!(model, network, variables, W, Y)
    println("   Voltage angle")
    constraints["voltage_angle"] = _define_voltage_angle_limit_constraints!(model, network, variables, W)
    println("   Voltage reference")
    constraints["voltage_reference"] = _define_voltage_reference_constraints!(model, network, variables, W)
    println("   Voltage module")
    constraints["voltage_module"] = _define_voltage_limit_constraints!(model, network, variables, W)
    println("   Linking constraints")
    constraints["linking_constraints"] = _define_linking_constraints!(model, variables, cliques, cliquetree; linking_edges=linking_edges)

    variables["W"] = W
    return model, variables, constraints
end


function _build_model_dec_no_lc(network, cliques, cliquetree; pb_path=nothing)
    model = Model(Mosek.Optimizer)
    Y = admittance_matrix_W(network)

    # Variables
    println("Defining cliques")
    variables = _define_cliques!(model, network, cliques)
    println("Defining power variables")
    merge!(variables, _define_generator_power_variables!(model, network))
    println("Mapping W")
    W = _map_W(model, network, cliques, variables)

    # Objective
    println("Defining objective")
    _define_objective!(model, network, variables)

    # Constraints
    constraints = Dict()
    if isnothing(pb_path)
        println("Defining power balance")
        constraints["power_balance"] = _define_power_balance_constraints!(model, network, variables, W, Y)
    else
        println("Loading power balance")
        constraints["power_balance"] = load_power_balance_constraints!(model, network, W, variables, pb_path)
    end
    println("Constraints")
    println("   Branch power")
    constraints["branch_power"] = _define_branch_power_limit_constraints!(model, network, variables, W, Y)
    W_array = _map_W_array(model, network, cliques, variables)
    println("   Voltage angle")
    constraints["voltage_angle"] = _define_voltage_angle_limit_constraints_no_lc!(model, network, variables, W_array)
    println("   Voltage reference")
    constraints["voltage_reference"] = _define_voltage_reference_constraints_no_lc!(model, network, variables, W_array)
    println("   Voltage module")
    constraints["voltage_module"] = _define_voltage_limit_constraints_no_lc!(model, network, variables, W_array)
    #println("   Linking constraints")
    #constraints["linking_constraints"] = _define_linking_constraints!(model, variables, cliques, cliquetree; linking_edges=linking_edges)

    variables["W"] = W
    return model, variables, constraints
end


function build_model(network, cliques=nothing, cliquetree=nothing; pb_path=nothing, linking_edges=nothing, no_lc=false)
    if isnothing(cliques) || isnothing(cliquetree)
        return _build_model(network; pb_path=pb_path)
    end
    if no_lc
        return _build_model_dec_no_lc(network, cliques, cliquetree; pb_path=pb_path)
    end
    return _build_model_dec(network, cliques, cliquetree; pb_path=pb_path, linking_edges=linking_edges)
end


function solve(network, cliques=nothing, cliquetree=nothing; pb_path=nothing, linking_edges=nothing, no_lc=false)
    if !hasgencost(network)
        println("Cannot solve network $(network.name). No cost found.")
        return nothing, nothing, nothing
    end
    build_time = @elapsed ((model, variables, constraints) = build_model(network, cliques, cliquetree; pb_path=pb_path, linking_edges=linking_edges, no_lc=no_lc))
    println("Building time: $build_time (s)")
    optimize!(model)
    return model, variables, constraints
end
