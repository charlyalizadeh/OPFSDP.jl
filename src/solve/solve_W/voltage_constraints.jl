function _define_voltage_angle_limit_constraints!(model, network, variables, W::LinearAlgebra.Symmetric)
    constraints = []
    n = nbus(network)
    for branch in branches(network)
        if (branch.angmin == 0 && branch.angmax == 0) || (branch.angmin <= -360 && branch.angmax >= 360)
            continue
        end
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        branch.angmin > -360 && push!(constraints, @constraint(model, -W[b, n + a] + W[n + b, a] >= tand(branch.angmin) * (W[b, a] + W[n + b, n + a])))
        branch.angmax < 360 && push!(constraints, @constraint(model, -W[b, n + a] + W[n + b, a] <= tand(branch.angmax) * (W[b, a] + W[n + b, n + a])))
        push!(constraints, @constraint(model, W[b, a] + W[n + b, n + a] >= 0))
    end
    return constraints
end


function _define_voltage_reference_constraints!(model, network, variables, W::LinearAlgebra.Symmetric)
    constraints = []
    refid = nbus(network) + normid(network, refbus(network).id)
    push!(constraints, @constraint(model, W[refid, refid] == 0))
    return constraints
end


function _define_voltage_limit_constraints!(model, network, variables, W::LinearAlgebra.Symmetric; all=false)
    constraints = []
    n = nbus(network)
    for bus in buses(network)
        b = normid(network, bus.id)
        push!(constraints, @constraint(model, W[b, b] + W[n + b, n + b] >= bus.vmin^2))
        push!(constraints, @constraint(model, W[b, b] + W[n + b, n + b] <= bus.vmax^2))
    end
    return constraints
end


