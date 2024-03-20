function inv_branch_ft(branch)
    branch_copy = copy(branch)
    temp = branch_copy.from
    branch_copy.from = branch_copy.to
    branch_copy.to = temp
    return branch_copy
end

function get_branches_in(network, bus_id)
    branches = []
    for branch in network.branches
        if branch.from == bus_id
            push!(branches, inv_branch_ft(branch))
        end
        if branch.to == bus_id
            push!(branches, branch)
        end
    end
    return branches
end

function get_branches_out(network, bus_id)
    branches = []
    for branch in network.branches
        if branch.to == bus_id
            push!(branches, inv_branch_ft(branch))
        end
        if branch.from == bus_id
            push!(branches, branch)
        end
    end
    return branches
end

function generators(network::PowerFlowNetwork)
    return vcat([gen for gen in values(network.generators)]...)
end
