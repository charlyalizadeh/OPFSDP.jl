function _define_branch_flow_limit_origin_constraints!(model, network, vvm)
	for branch in network.branches
        if isinf(branch.rateA)
            continue
        end
		current = branch_compute_current_origin(branch)
		@constraint(model,
					2*real(current[1])*real(current[2])*vvm["imag(v$(branch.src))*imag(v$(branch.dst))"] +
					2*real(current[1])*imag(current[2])*vvm["imag(v$(branch.src))*real(v$(branch.dst))"] -
					2*imag(current[1])*real(current[2])*vvm["imag(v$(branch.src))*real(v$(branch.dst))"] -
					2*real(current[1])*imag(current[2])*vvm["imag(v$(branch.dst))*real(v$(branch.src))"] +
					2*imag(current[1])*real(current[2])*vvm["imag(v$(branch.dst))*real(v$(branch.src))"] +
					2*imag(current[1])*imag(current[2])*vvm["real(v$(branch.src))*real(v$(branch.dst))"] +
					2*imag(current[1])*imag(current[2])*vvm["imag(v$(branch.src))*imag(v$(branch.dst))"] +
					2*real(current[1])*real(current[2])*vvm["real(v$(branch.src))*real(v$(branch.dst))"] +
					real(current[1])^2*vvm["imag(v$(branch.src))*imag(v$(branch.src))"] +
					imag(current[1])^2*vvm["real(v$(branch.src))*real(v$(branch.src))"] +
					imag(current[1])^2*vvm["imag(v$(branch.src))*imag(v$(branch.src))"] +
					real(current[1])^2*vvm["real(v$(branch.src))*real(v$(branch.src))"] +
					real(current[2])^2*vvm["imag(v$(branch.dst))*imag(v$(branch.dst))"] +
					imag(current[2])^2*vvm["real(v$(branch.dst))*real(v$(branch.dst))"] +
					imag(current[2])^2*vvm["imag(v$(branch.dst))*imag(v$(branch.dst))"] +
					real(current[2])^2*vvm["real(v$(branch.dst))*real(v$(branch.dst))"] <= branch.rateA^2)
	end
end


function _define_branch_flow_limit_destination_constraints!(model, network, vvm)
	for branch in network.branches
        if isinf(branch.rateA)
            continue
        end
		current = branch_compute_current_destination(branch)
		@constraint(model,
					2*real(current[1])*real(current[2])*vvm["imag(v$(branch.src))*imag(v$(branch.dst))"] +
					2*real(current[1])*imag(current[2])*vvm["imag(v$(branch.src))*real(v$(branch.dst))"] -
					2*imag(current[1])*real(current[2])*vvm["imag(v$(branch.src))*real(v$(branch.dst))"] -
					2*real(current[1])*imag(current[2])*vvm["imag(v$(branch.dst))*real(v$(branch.src))"] +
					2*imag(current[1])*real(current[2])*vvm["imag(v$(branch.dst))*real(v$(branch.src))"] +
					2*imag(current[1])*imag(current[2])*vvm["real(v$(branch.src))*real(v$(branch.dst))"] +
					2*imag(current[1])*imag(current[2])*vvm["imag(v$(branch.src))*imag(v$(branch.dst))"] +
					2*real(current[1])*real(current[2])*vvm["real(v$(branch.src))*real(v$(branch.dst))"] +
					real(current[1])^2*vvm["imag(v$(branch.src))*imag(v$(branch.src))"] +
					imag(current[1])^2*vvm["real(v$(branch.src))*real(v$(branch.src))"] +
					imag(current[1])^2*vvm["imag(v$(branch.src))*imag(v$(branch.src))"] +
					real(current[1])^2*vvm["real(v$(branch.src))*real(v$(branch.src))"] +
					real(current[2])^2*vvm["imag(v$(branch.dst))*imag(v$(branch.dst))"] +
					imag(current[2])^2*vvm["real(v$(branch.dst))*real(v$(branch.dst))"] +
					imag(current[2])^2*vvm["imag(v$(branch.dst))*imag(v$(branch.dst))"] +
					real(current[2])^2*vvm["real(v$(branch.dst))*real(v$(branch.dst))"] <= branch.rateA^2)
	end
end


function _define_branch_flow_limit_constraints!(model, network, vvm)
	_define_branch_flow_limit_origin_constraints!(model, network, vvm)
	_define_branch_flow_limit_destination_constraints!(model, network, vvm)
end
