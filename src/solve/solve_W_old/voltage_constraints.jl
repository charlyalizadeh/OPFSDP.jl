function _define_voltage_angle_limit_constraints!(model, network, variables, W::LinearAlgebra.Symmetric)
    constraints = []
    for branch in branches(network)
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        _theta_real = theta_real(network, branch.from, branch.to)
        _theta_imag = theta_imag(network, branch.from, branch.to)
        branch.angmin > -360 && push!(constraints, @constraint(model, trJuMP(model, _theta_imag, W) >= tand(branch.angmin) * trJuMP(model, _theta_real, W)))
        branch.angmax < 360 && push!(constraints, @constraint(model, trJuMP(model, _theta_imag, W) <= tand(branch.angmax) * trJuMP(model, _theta_real, W)))
        if branch.angmin > -360 || branch.angmax < 360
            push!(constraints, @constraint(model, trJuMP(model, _theta_real, W) >= 0))
        end
    end
    return constraints
end


function _define_voltage_reference_constraints!(model, network, variables, W::LinearAlgebra.Symmetric)
    constraints = []
    eb = vcat(zeros(nbus(network)), base(network, refbus(network).id))
    push!(constraints, @constraint(model, trJuMP(model, eb * transpose(eb), W) == 0))
    return constraints
end


function _define_voltage_limit_constraints!(model, network, variables, W::LinearAlgebra.Symmetric)
    constraints = []
    _nbus = nbus(network)
    for bus in buses(network)
        _theta_real = theta_real(network, bus.id, bus.id)
        b = normid(network, bus.id)
        push!(constraints, @constraint(model, trJuMP(model, _theta_real, W) >= bus.vmin^2))
        push!(constraints, @constraint(model, trJuMP(model, _theta_real, W) <= bus.vmax^2))
    end
    return constraints
end
