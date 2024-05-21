function _branch_compute_current_from_from(branch)
    return (1 / (branch.r + im * branch.x) + im * branch.b / 2) / branch.tf_ratio^2
	#return (branch.admittance + im * (branch.susceptance / 2)) / branch.tf_ratio^2
end

function _branch_compute_current_from_to(branch)
    return - 1 / ((branch.r + im * branch.x) * branch.tf_ratio * exp(-im * branch.tf_ps_angle))
	#return -branch.admittance / (branch.tf_ratio * exp(-im * branch.tf_ps_angle))
end

function branch_compute_current_from(branch)
	return [_branch_compute_current_from_from(branch), _branch_compute_current_from_to(branch)]
end

function _branch_compute_current_to_from(branch)
    return - 1 / ((branch.r + im * branch.x) * branch.tf_ratio * exp(im * branch.tf_ps_angle))
	#return -branch.admittance / (branch.tf_ratio * exp(im * branch.tf_ps_angle))
end

function _branch_compute_current_to_to(branch)
    return 1 / (branch.r + im * branch.x) + im * branch.b / 2
	#return branch.admittance + im * (branch.susceptance / 2)
end

function branch_compute_current_to(branch)
	return [_branch_compute_current_to_from(branch), _branch_compute_current_to_to(branch)]
end


yff(branch) = _branch_compute_current_from_from(branch)
yft(branch) = _branch_compute_current_from_to(branch)
ytf(branch) = _branch_compute_current_to_from(branch)
ytt(branch) = _branch_compute_current_to_to(branch)
Y(branch) = [yff(branch) yft(branch); ytf(branch) ytt(branch)]


function admittance_matrix_W(network)
    matrix = zeros(Complex, nbus(network), nbus(network))
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        matrix[b, a] += yft(branch)
        matrix[b, a] += ytf(branch)
        matrix[a, b] += matrix[b, a]
    end
    for bus in buses(network)
        b = normid(network, bus.id)
        _branches = branches(network, bus.id)
        matrix[b, b] = bus.shunt_admittance
        if !isempty(_branches)
            matrix[b, b] += sum(yff.(_branches))
            matrix[b, b] += sum(ytt.(_branches))
        end
    end
    return matrix
end

function admittance_matrix_X(network)
    matrix = zeros(Complex, nbus(network), nbus(network))
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        matrix[b, a] += yft(branch)
        matrix[b, a] += ytf(branch)
        matrix[a, b] += matrix[b, a]
    end
    for bus in buses(network)
        b = normid(network, bus.id)
        _branches = branches(network, bus.id)
        matrix[b, b] = bus.shunt_admittance
        if !isempty(_branches)
            matrix[b, b] += sum(yff.(_branches))
            matrix[b, b] += sum(ytt.(_branches))
        end
    end
    return matrix
end

#function admittance_matrix(network)
#    matrix = zeros(Complex, nbus(network), nbus(network))
#    order = network.buses_order
#    for i in 1:nbus(network)
#        for j in 1:nbus(network)
#            bus_i = network.buses[order[i]]
#            bus_j = network.buses[order[j]]
#            if i == j
#                _branches = branches(network, bus_i.id)
#                matrix[i, j] = bus_i.shunt_admittance
#                if !isempty(_branches)
#                    matrix[i, j] += sum(yff.(_branches))
#                    matrix[i, j] += sum(ytt.(_branches))
#                end
#            else
#                _branches = branches(network, bus_i.id, bus_j.id)
#                if !isempty(_branches)
#                    matrix[i, j] += sum(yft.(_branches))
#                    matrix[i, j] += sum(ytf.(_branches))
#                end
#            end
#        end
#    end
#    return matrix
#end
