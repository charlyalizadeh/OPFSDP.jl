function _branch_compute_power_origin_1(branch)
	return (conj(branch.admittance) - branch.susceptance * im) / branch.tf_ratio^2
end

function _branch_compute_power_origin_2(branch)
	return -conj(branch.admittance) * exp(branch.tf_ps_angle * im) / branch.tf_ratio
end

function branch_compute_power_origin(branch)
	return [_branch_compute_power_origin_1(branch), _branch_compute_power_origin_2(branch)]
end

function _branch_compute_power_destination_1(branch)
	return conj(branch.admittance) - branch.susceptance * im
end

function _branch_compute_power_destination_2(branch)
	return -conj(branch.admittance) * exp(-branch.tf_ps_angle * im) / branch.tf_ratio
end

function branch_compute_power_destination(branch)
	return [_branch_compute_power_destination_1(branch), _branch_compute_power_destination_2(branch)]
end
