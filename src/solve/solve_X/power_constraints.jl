function _define_branch_flow_constraints!(model, network, variables, X, Y)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        @constraint(model, conj(Y[b, a]) * X["$b, $b"] - conj(Y[b, a]) * X["$b, $a"] == variables["S_$(b)_$(a)"])
        @constraint(model, conj(Y[b, a]) * X["$a, $a"] - conj(Y[b, a]) * conj(X["$b, $a"]) == variables["S_$(a)_$(b)"])
        if branch.rateA != 0 && !isinf(branch.rateA)
            @constraint(model, real(variables["S_$(b)_$(a)"])^2 + imag(variables["S_$(b)_$(a)"])^2  <= branch.rateA^2)
            @constraint(model, real(variables["S_$(a)_$(b)"])^2 + imag(variables["S_$(a)_$(b)"])^2  <= branch.rateA^2)
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
                    sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id)) - sum(bus.load) ==
                    _sum_branch_flow_L0!(model, network, variables, bus.id) +
                    _sum_branch_flow_L1!(model, network, variables, bus.id))
    end
end
