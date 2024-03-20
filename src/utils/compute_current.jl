function _branch_compute_current_from_from(branch)
	return (branch.admittance + im * (branch.susceptance / 2)) / branch.tf_ratio^2
end

function _branch_compute_current_from_to(branch)
	return -branch.admittance / (branch.tf_ratio * exp(-im * branch.tf_ps_angle))
end

function branch_compute_current_from(branch)
	return [_branch_compute_current_from_from(branch), _branch_compute_current_from_to(branch)]
end

function _branch_compute_current_to_from(branch)
	return -branch.admittance / (branch.tf_ratio * exp(im * branch.tf_ps_angle))
end

function _branch_compute_current_to_to(branch)
	return branch.admittance + im * (branch.susceptance / 2)
end

function branch_compute_current_to(branch)
	return [_branch_compute_current_to_from(branch), _branch_compute_current_to_to(branch)]
end

yff(branch) = _branch_compute_current_from_from(branch)
yft(branch) = _branch_compute_current_from_to(branch)
ytf(branch) = _branch_compute_current_to_from(branch)
ytt(branch) = _branch_compute_current_to_to(branch)
Y(branch) = [yff(branch) yft(branch); ytf(branch) ytt(branch)]
