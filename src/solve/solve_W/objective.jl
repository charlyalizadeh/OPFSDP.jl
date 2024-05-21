function _define_objective_gen!(model, network, variables, gen; degree = 2)
	if degree < 0
		throw(DomainError(degree, "degree should be superior or equal to 1, got $degree"))
	end
    real_degree = min(degree+1, length(gen.active_cost_coeff))
	costs = reverse(gen.active_cost_coeff)
    return @expression(model, sum(costs[i] * real(variables["S_$(gen.genid)"])^(i - 1)  for i in 1:real_degree))
end

#function _define_objective_gen_array!(model, network, variables, gen_array, degree)
#	return @expression(model, sum(_define_objective_gen!(model, network, variables, gen, degree) for gen in gen_array))
#end

function _define_objective!(model, network, variables; degree = 2)
    @objective(model, Min, sum(_define_objective_gen!(model, network, variables, gen; degree = degree) for gen in generators(network)))
end
