function _get_branch_power_out_real!(model, network, bus, vvm)
    branches_out = get_branches_out(network, bus.id)
    @expression(model, sum(real(yff(branch))*(vvm["real(v$(branch.from))*real(v$(branch.from))"] + vvm["imag(v$(branch.from))*imag(v$(branch.from))"]) +
                           real(yft(branch))*(vvm["real(v$(branch.from))*real(v$(branch.to))"] + vvm["imag(v$(branch.from))*imag(v$(branch.to))"]) +
                           imag(yft(branch))*(vvm["imag(v$(branch.from))*real(v$(branch.to))"] + vvm["real(v$(branch.from))*imag(v$(branch.to))"])
                           for branch in branches_out)
                )
end

function _get_branch_power_out_imag!(model, network, bus, vvm)
    branches_out = get_branches_out(network, bus.id)
    @expression(model, sum(-imag(yff(branch))*(vvm["real(v$(branch.from))*real(v$(branch.from))"] + vvm["imag(v$(branch.from))*imag(v$(branch.from))"]) +
                           real(yft(branch))*(vvm["imag(v$(branch.from))*real(v$(branch.to))"] - vvm["real(v$(branch.from))*imag(v$(branch.to))"]) -
                           imag(yft(branch))*(vvm["real(v$(branch.from))*real(v$(branch.to))"] + vvm["imag(v$(branch.from))*imag(v$(branch.to))"])
                           for branch in branches_out)
                )
end


function _get_branch_power_in_real!(model, network, bus, vvm)
    branches_in = get_branches_in(network, bus.id)
    @expression(model, sum(real(ytt(branch))*(vvm["real(v$(branch.from))*real(v$(branch.from))"] + vvm["imag(v$(branch.from))*imag(v$(branch.from))"]) +
                           real(ytf(branch))*(vvm["real(v$(branch.from))*real(v$(branch.to))"] + vvm["imag(v$(branch.from))*imag(v$(branch.to))"]) +
                           imag(ytf(branch))*(vvm["imag(v$(branch.from))*real(v$(branch.to))"] + vvm["real(v$(branch.from))*imag(v$(branch.to))"])
                           for branch in branches_in)
                )
end


function _get_branch_power_in_imag!(model, network, bus, vvm)
    branches_in = get_branches_in(network, bus.id)
    @expression(model, sum(-imag(ytt(branch))*(vvm["real(v$(branch.from))*real(v$(branch.from))"] + vvm["imag(v$(branch.from))*imag(v$(branch.from))"]) +
                           real(ytf(branch))*(vvm["imag(v$(branch.from))*real(v$(branch.to))"] - vvm["real(v$(branch.from))*imag(v$(branch.to))"]) -
                           imag(ytf(branch))*(vvm["real(v$(branch.from))*real(v$(branch.to))"] + vvm["imag(v$(branch.from))*imag(v$(branch.to))"])
                           for branch in branches_in)
                )
end


function _define_power_balance_constraints!(model, network, variables, vvm)
    for (id, bus) in network.buses
        @constraint(model, variables["real(S_$(id))"] == real(bus.load) +
                                                             _get_branch_power_out_real!(model, network, bus, vvm) +
                                                             _get_branch_power_in_real!(model, network, bus, vvm))
        @constraint(model, variables["imag(S_$(id))"] == imag(bus.load) +
                                                             _get_branch_power_out_imag!(model, network, bus, vvm) +
                                                             _get_branch_power_in_imag!(model, network, bus, vvm))
        if !(id in keys(network.generators))
            @constraint(model, variables["real(S_$(bus.id))"] == 0.0)
            @constraint(model, variables["imag(S_$(bus.id))"] == 0.0)
        end
    end
end
