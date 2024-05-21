function _define_generator_power_limit_constraints!(model, network, variables)
    for gen in generators(network)
        !isinf(gen.Pmax) && set_upper_bound(real(variables["S_$(gen.genid)"]), gen.Pmax)
		!isinf(gen.Pmin) && set_lower_bound(real(variables["S_$(gen.genid)"]), gen.Pmin)
		!isinf(gen.Qmax) && set_upper_bound(imag(variables["S_$(gen.genid)"]), gen.Qmax)
		!isinf(gen.Qmin) && set_lower_bound(imag(variables["S_$(gen.genid)"]), gen.Qmin)
	end
end


function _define_branch_flow_constraints!(model, network, variables, X)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        @constraint(model, conj(yff(branch)) * X["$b, $b"] + conj(yft(branch)) * X["$b, $a"] == variables["S_$(b)_$(a)"])
        @constraint(model, conj(ytf(branch)) * X["$a, $b"] + conj(ytt(branch)) * X["$a, $a"] == variables["S_$(a)_$(b)"])
        if !isinf(branch.rateA)
            Sb = branch.rateA * network.buses[branch.from].vmin
            Sa = branch.rateA * network.buses[branch.to].vmin
            @constraint(model, real(variables["S_$(b)_$(a)"])^2 + imag(variables["S_$(b)_$(a)"])^2 <= Sb^2)
            @constraint(model, real(variables["S_$(a)_$(b)"])^2 + imag(variables["S_$(a)_$(b)"])^2 <= Sa^2)
        end
    end
end


function _sum_branch_flow_L0!(model, network, variables, bus_id)
    return @expression(model, sum(variables["S_$(normid(network, b.from))_$(normid(network, b.to))"] for b in branches(network, bus_id)))
end

function _sum_branch_flow_L1!(model, network, variables, bus_id)
    return @expression(model, sum(variables["S_$(normid(network, b.to))_$(normid(network, b.from))"] for b in branches(network, bus_id)))
end


function _define_power_balance_constraints!(model, network, variables, X)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model,
                    _sum_branch_flow_L0!(model, network, variables, bus.id) +
                    _sum_branch_flow_L1!(model, network, variables, bus.id) +
                    sum(bus.load) +
                    conj(bus.shunt_admittance) * X["$b, $b"] -
                    sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id)) == 0
                   )
    end
end
