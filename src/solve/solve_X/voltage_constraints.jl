function _define_voltage_angle_limit_constraints!(model, network, X::DefaultDict)
    for branch in branches(network)
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        angmin = branch.angmin
        angmax = branch.angmax
        angmin > -90 && @constraint(model, (tan(angmin) + im) * X["$b, $a"] + (tan(angmin) - im) * X["$a, $b"] <= 0)
        angmax < 90 && @constraint(model, (tan(angmax) + im) * X["$b, $a"] + (tan(angmax) - im) * X["$a, $b"] >= 0)
        @constraint(model, real(X["$b, $a"]) + real(X["$a, $b"]) >= 0)
    end
end


function _define_voltage_angle_limit_constraints!(model, network, X::LinearAlgebra.Hermitian)
    for branch in branches(network)
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        angmin = branch.angmin
        angmax = branch.angmax
        angmin > -90 && @constraint(model, (tan(angmin) + im) * X[b, a] + (tan(angmin) - im) * X[a, b] <= 0)
        angmax < 90 && @constraint(model, (tan(angmax) + im) * X[b, a] + (tan(angmax) - im) * X[a, b] >= 0)
        @constraint(model, real(X[b, a]) + real(X[a, b]) >= 0)
    end
end


function _define_voltage_limit_constraints!(model, network, X::DefaultDict)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model, real(X["$b, $b"]) >= bus.vmin^2)
        @constraint(model, real(X["$b, $b"]) <= bus.vmax^2)
        #@constraint(model, imag(X["$b, $b"]) == 0)
    end
end


function _define_voltage_limit_constraints!(model, network, X::LinearAlgebra.Hermitian)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model, real(X[b, b]) >= bus.vmin^2)
        @constraint(model, real(X[b, b]) <= bus.vmax^2)
        @constraint(model, imag(X[b, b]) == 0)
    end
end
