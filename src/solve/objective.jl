function _define_objective_bus_quadratic!(model, network, variables, gen)
	return @expression(model, sum(c * variables["real(S_$(gen.id))"]^(length(gen.active_cost_coeff) - i)  for (i, c) in enumerate(gen.active_cost_coeff)))
end

function _define_objective_bus_linear!(model, network, variables, gen)
	return @expression(model, gen.active_cost_coeff[end - 1] * variables["real(S_$(gen.id))"] + gen.active_cost_coeff[end])
end

function _define_objective!(model, network, variables)
    @objective(model, Min, sum(_define_objective_bus_quadratic!(model, network, variables, gen_array[1]) for gen_array in values(network.generators)))
end
