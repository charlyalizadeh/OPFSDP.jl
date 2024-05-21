module SolveX

import ...OPFSDP: generators, buses, branches, nbus, nbranch, ngen, normid, trueid, refbus, hasgen, hasgencost, hasbranch_directed, hasbranch, yff, yft, ytf, ytt, admittance_matrix_X
using JuMP, Mosek, MosekTools
export solve_X

include("variables.jl")
include("objective.jl")
include("power_constraints.jl")
include("voltage_constraints.jl")

function build_model(network, cliques, cliquetree)
    model = Model(Mosek.Optimizer)
    Y = admittance_matrix_X(network)

    # Variables
    variables = _define_cliques!(model, network, cliques)
    merge!(variables, _define_generator_power_variables!(model, network))
    merge!(variables, _define_flow_variables!(model, network))
    X = _map_X!(model, network, cliques, variables)


    # Objective
    _define_objective!(model, network, variables)

    # Constraints
    # Power
    _define_branch_flow_constraints!(model, network, variables, X, Y)
    _define_power_balance_constraints!(model, network, variables, X)
    # Voltage
    _define_voltage_angle_limit_constraints!(model, network, X)
    _define_voltage_limit_constraints!(model, network, X)

    return model
end


function solve_X(network, cliques, cliquetree)
    build_time = @elapsed (model = build_model(network, cliques, cliquetree))
    println("Building time: $build_time (s)")
    optimize!(model)
    return model
end

end
