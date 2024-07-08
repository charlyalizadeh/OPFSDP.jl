function _define_objective_polynomial_gen!(model, network, variables, gen; degree = 2)
	if degree < 0
		throw(DomainError(degree, "degree should be superior or equal to 1, got $degree"))
	end
    real_degree = min(degree+1, length(gen.active_cost_coeff))
	costs = reverse(gen.active_cost_coeff)
    return @expression(model, sum(costs[i] * (network.Sbase * variables["real(S_$(gen.genid))"])^(i - 1) for i in 1:real_degree))
end

function _define_objective_polynomial!(model, network, variables; degree = 2)
    @objective(model, Min, sum(_define_objective_polynomial_gen!(model, network, variables, gen; degree = degree) for gen in generators(network) if gen.status != 0))
end

function _define_objective_rawgo_gen!(model, network, variables, gen)
    costs = [c["c"] for c in gen.active_cost_coeff]
    return @expression(model, sum(costs[i] * variables["real(S_$(gen.genid)_$i)"] for i in 1:length(costs)))
end

function _define_objective_rawgo!(model, network, variables)
    @objective(model, Min, sum(_define_objective_rawgo_gen!(model, network, variables, gen) for gen in generators(network) if gen.status != 0))
end

function _define_objective!(model, network, variables; degree = 2)
    obj = @objective(model, Min, sum(gen.active_cost_type == rawgo ? _define_objective_rawgo_gen!(model, network, variables, gen) : _define_objective_polynomial_gen!(model, network, variables, gen; degree = degree)
                               for gen in generators(network) if gen.status != 0))
    println(obj)
    return obj
end
