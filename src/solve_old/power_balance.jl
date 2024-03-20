function _get_branch_power_out_real!(model, network, bus, vvm)
	branches_out = get_branches_out(network, bus.id)
    @expression(model, sum(real(_branch_compute_power_origin_1(branch))*(vvm["real(v$(bus.id))*real(v$(bus.id))"] + vvm["imag(v$(bus.id))*imag(v$(bus.id))"]) +
                           real(_branch_compute_power_origin_2(branch))*(vvm["imag(v$(bus.id))*imag(v$(branch.dst))"] + vvm["real(v$(bus.id))*real(v$(branch.dst))"])
					       for branch in branches_out)
				)
end

function _get_branch_power_out_imag!(model, network, bus, vvm)
	branches_out = get_branches_out(network, bus.id)
	@expression(model, sum(imag(_branch_compute_power_origin_1(branch))*(vvm["real(v$(bus.id))*real(v$(bus.id))"] + vvm["imag(v$(bus.id))*imag(v$(bus.id))"]) +
                           imag(_branch_compute_power_origin_2(branch))*(vvm["imag(v$(bus.id))*real(v$(branch.dst))"] + vvm["real(v$(bus.id))*imag(v$(branch.dst))"])
                           for branch in branches_out)
				)
end


function _get_branch_power_in_real!(model, network, bus, vvm)
	branches_in = get_branches_in(network, bus.id)
    @expression(model, sum(real(_branch_compute_power_destination_1(branch))*(vvm["real(v$(bus.id))*real(v$(bus.id))"] + vvm["imag(v$(bus.id))*imag(v$(bus.id))"]) +
                           real(_branch_compute_power_destination_2(branch))*(vvm["imag(v$(bus.id))*imag(v$(branch.src))"] + vvm["real(v$(bus.id))*real(v$(branch.src))"])
					       for branch in branches_in)
				)
end


function _get_branch_power_in_imag!(model, network, bus, vvm)
	branches_in = get_branches_in(network, bus.id)
	@expression(model, sum(imag(_branch_compute_power_destination_1(branch))*(vvm["real(v$(bus.id))*real(v$(bus.id))"] + vvm["imag(v$(bus.id))*imag(v$(bus.id))"]) +
                           imag(_branch_compute_power_destination_2(branch))*(vvm["imag(v$(bus.id))*real(v$(branch.src))"] + vvm["real(v$(bus.id))*imag(v$(branch.src))"])
					       for branch in branches_in)
				)
end


function _define_power_balance_constraints!(model, network, variables, vvm)
	for (id, bus) in network.buses
		@constraint(model, variables["real(S_$(id))"] == real(bus.load) +
															 _get_branch_power_out_real!(model, network, bus, vvm) -
															 _get_branch_power_in_real!(model, network, bus, vvm))
		@constraint(model, variables["imag(S_$(id))"] == imag(bus.load) +
															 _get_branch_power_out_imag!(model, network, bus, vvm) -
															 _get_branch_power_in_imag!(model, network, bus, vvm))
        if !(id in keys(network.generators))
            println("BUS $(id) IS NOT GENERATOR")
			@constraint(model, variables["real(S_$(bus.id))"] == 0.0)
			@constraint(model, variables["imag(S_$(bus.id))"] == 0.0)
		end
	end
end
