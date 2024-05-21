function _define_voltage_angle_limit_constraints!(model, network, X)
    for branch in branches(network)
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        angmin = branch.angmin
        angmax = branch.angmax
        angmin > -360 && @constraint(model, imag(X["$b, $a"]) >= tand(angmin) * real(X["$b, $a"]))
        angmax < 360 && @constraint(model, imag(X["$b, $a"]) <= tand(angmax) * real(X["$b, $a"]))
    end
end


function _define_voltage_limit_constraints!(model, network, X)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model, real(X["$b, $b"]) >= bus.vmin^2)
        @constraint(model, real(X["$b, $b"]) <= bus.vmax^2)
        @constraint(model, imag(X["$b, $b"]) == 0)
    end
end
