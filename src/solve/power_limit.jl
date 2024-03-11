function _define_power_limit_constraints!(model, network, variables)
    for (id, gen_array) in network.generators
        gen = gen_array[1]
		!isinf(gen.Pmax) && @constraint(model, variables["real(S_$(gen.id))"] <= gen.Pmax)
		!isinf(gen.Pmin) && @constraint(model, variables["real(S_$(gen.id))"] >= gen.Pmin)
		!isinf(gen.Qmax) && @constraint(model, variables["imag(S_$(gen.id))"] <= gen.Qmax)
		!isinf(gen.Qmin) && @constraint(model, variables["imag(S_$(gen.id))"] >= gen.Qmin)
	end
end
