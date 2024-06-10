function _sum_branch_flow_L0!(model, network, variables, bus_id)
    return @expression(model, sum(variables["S_$(normid(network, b.from))_$(normid(network, b.to))"] for b in branches(network, bus_id)))
end


function _sum_branch_flow_L1!(model, network, variables, bus_id)
    return @expression(model, sum(variables["S_$(normid(network, b.to))_$(normid(network, b.from))"] for b in branches(network, bus_id)))
end


function _sum_branch_flow!(model, network, variables, bus_id)
    return @expression(model, sum(variables["S_$(normid(network, bus_id))_$(normid(network, b.from == bus_id ? b.to : b.from))"] for b in branches(network, bus_id)))
end



function _define_power_balance_constraints!(model, network, variables, X::DefaultDict)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model,
                    _sum_branch_flow!(model, network, variables, bus.id) +
                    bus.load[1] +
                    conj(bus.shunt_admittance) * X["$b, $b"] -
                    sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id)) == 0
                   )

    end
end

function _define_power_balance_constraints!(model, network, variables, X::LinearAlgebra.Hermitian)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model,
                    _sum_branch_flow!(model, network, variables, bus.id) +
                    bus.load[1] +
                    conj(bus.shunt_admittance) * X[b, b] -
                    sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id)) == 0
                   )

    end
end

function _define_branch_flow_constraints!(model, network, variables, X::DefaultDict, Y)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        @constraint(model, conj(Y["Yff"][b, a]) * X["$b, $b"] + conj(Y["Yft"][b, a]) * X["$b, $a"] == variables["S_$(b)_$(a)"])
        @constraint(model, conj(Y["Ytf"][b, a]) * X["$a, $b"] + conj(Y["Ytt"][b, a]) * X["$a, $a"] == variables["S_$(a)_$(b)"])
        if branch.rateA != 0 && !isinf(branch.rateA)
            SU = (branch.rateA / network.buses[branch.from].vmax)^2
            @constraint(model, real(variables["S_$(b)_$(a)"])^2 + imag(variables["S_$(b)_$(a)"])^2  <= SU)
            @constraint(model, real(variables["S_$(a)_$(b)"])^2 + imag(variables["S_$(a)_$(b)"])^2  <= SU)
        end
    end
end


function _define_branch_flow_constraints!(model, network, variables, X::LinearAlgebra.Hermitian, Y)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        @constraint(model, conj(Y["Yff"][b, a]) * X[b, b] + conj(Y["Yft"][b, a]) * X[b, a] == variables["S_$(b)_$(a)"])
        @constraint(model, conj(Y["Ytf"][b, a]) * X[a, b] + conj(Y["Ytt"][b, a]) * X[a, a] == variables["S_$(a)_$(b)"])
        if branch.rateA != 0 && !isinf(branch.rateA)
            SU = (branch.rateA / network.buses[branch.from].vmax)^2
            @constraint(model, real(variables["S_$(b)_$(a)"])^2 + imag(variables["S_$(b)_$(a)"])^2  <= SU)
            @constraint(model, real(variables["S_$(a)_$(b)"])^2 + imag(variables["S_$(a)_$(b)"])^2  <= SU)
        end
    end
end
