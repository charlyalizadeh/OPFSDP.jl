function _define_branch_flow_limit_origin_constraints!(model, network, vvm)
	for branch in network.branches
        if isinf(branch.rateA)
            continue
        end
        _yff, _yft = yff(branch), yft(branch)
        @constraint(model,
                    abs2(_yff) * (vvm["real(v$(branch.from))*real(v$(branch.from))"] + vvm["imag(v$(branch.from))*imag(v$(branch.from))"]) +
                    abs2(_yft) * (vvm["real(v$(branch.to))*real(v$(branch.to))"] + vvm["imag(v$(branch.to))*imag(v$(branch.to))"]) +
                    2 * (real(_yff) * real(_yft) * vvm["real(v$(branch.from))*real(v$(branch.to))"] +
                         imag(_yff) * imag(_yft) * vvm["imag(v$(branch.from))*imag(v$(branch.to))"] +
                         real(_yff) * real(_yft) * vvm["imag(v$(branch.from))*imag(v$(branch.to))"] +
                         imag(_yff) * imag(_yft) * vvm["real(v$(branch.from))*real(v$(branch.to))"] -
                         real(_yff) * imag(_yft) * vvm["real(v$(branch.from))*imag(v$(branch.to))"] -
                         imag(_yff) * real(_yft) * vvm["imag(v$(branch.from))*real(v$(branch.to))"] +
                         real(_yff) * imag(_yft) * vvm["imag(v$(branch.from))*real(v$(branch.to))"] +
                         imag(_yff) * real(_yft) * vvm["real(v$(branch.from))*imag(v$(branch.to))"]) <= branch.rateA^2)
	end
end


function _define_branch_flow_limit_destination_constraints!(model, network, vvm)
	for branch in network.branches
        if isinf(branch.rateA)
            continue
        end
        _ytf, _ytt = ytf(branch), ytt(branch)
        @constraint(model,
                    abs2(_ytf) * (vvm["real(v$(branch.to))*real(v$(branch.to))"] + vvm["imag(v$(branch.to))*imag(v$(branch.to))"]) +
                    abs2(_ytt) * (vvm["real(v$(branch.from))*real(v$(branch.from))"] + vvm["imag(v$(branch.from))*imag(v$(branch.from))"]) +
                    2 * (real(_ytf) * real(_ytt) * vvm["real(v$(branch.to))*real(v$(branch.from))"] +
                         imag(_ytf) * imag(_ytt) * vvm["imag(v$(branch.to))*imag(v$(branch.from))"] +
                         real(_ytf) * real(_ytt) * vvm["imag(v$(branch.to))*imag(v$(branch.from))"] +
                         imag(_ytf) * imag(_ytt) * vvm["real(v$(branch.to))*real(v$(branch.from))"] -
                         real(_ytf) * imag(_ytt) * vvm["real(v$(branch.to))*imag(v$(branch.from))"] -
                         imag(_ytf) * real(_ytt) * vvm["imag(v$(branch.to))*real(v$(branch.from))"] +
                         real(_ytf) * imag(_ytt) * vvm["imag(v$(branch.to))*real(v$(branch.from))"] +
                         imag(_ytf) * real(_ytt) * vvm["real(v$(branch.to))*imag(v$(branch.from))"]) <= branch.rateA^2)
	end
end


function _define_branch_flow_limit_constraints!(model, network, vvm)
	_define_branch_flow_limit_origin_constraints!(model, network, vvm)
	_define_branch_flow_limit_destination_constraints!(model, network, vvm)
end
