function _define_objective_gen_polynomial!(model, network, variables, gen; degree = 2)
	if degree < 0
		throw(DomainError(degree, "degree should be superior or equal to 1, got $degree"))
	end
    real_degree = min(degree+1, length(gen.active_cost_coeff))
	costs = reverse(gen.active_cost_coeff)
    return @expression(model, sum(costs[i] * (network.Sbase * real(variables["S_$(gen.genid)"]))^(i - 1) for i in 1:real_degree))
end


function _define_objective_polynomial!(model, network, variables; degree = 2)
    @objective(model, Min, sum(_define_objective_gen_polynomial!(model, network, variables, gen; degree = degree) for gen in generators(network) if gen.status != 0))
end
