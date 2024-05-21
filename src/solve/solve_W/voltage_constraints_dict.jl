function _define_voltage_angle_limit_constraints!(model, network, variables, W::DefaultDict)
    constraints = []
    _nbus = nbus(network)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        #push!(constraints, @constraint(model,  W["$(b), $(a)"] + W["$(_nbus + b), $(_nbus + a)"] >= 0))
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        branch.angmin > -360 && push!(constraints, @constraint(model, W["$(b), $(_nbus + a)"] - W["$(a), $(_nbus + b)"] >=
                                                               tand(branch.angmin) * (W["$(b), $(a)"] + W["$(_nbus + b), $(_nbus + a)"])))
        branch.angmax < 360 && push!(constraints, @constraint(model, W["$(b), $(_nbus + a)"] - W["$(a), $(_nbus + b)"] <=
                                                              tand(branch.angmax) * (W["$(b), $(a)"] + W["$(_nbus + b), $(_nbus + a)"])))
    end
    return constraints
end


function _define_voltage_reference_constraints!(model, network, variables, W::DefaultDict)
    constraints = []
    refid = nbus(network) + normid(network, refbus(network).id)
    push!(constraints, @constraint(model, W["$(refid), $(refid)"] == 0))
    return constraints
end


function _define_voltage_limit_constraints!(model, network, variables, W::DefaultDict)
    constraints = []
    _nbus = nbus(network)
    for bus in buses(network)
        b = normid(network, bus.id)
        push!(constraints, @constraint(model, W["$(b), $(b)"] + W["$(_nbus + b), $(_nbus + b)"] >= bus.vmin^2))
        push!(constraints, @constraint(model, W["$(b), $(b)"] + W["$(_nbus + b), $(_nbus + b)"] <= bus.vmax^2))
    end
    return constraints
end


function _define_voltage_angle_limit_constraints_no_lc!(model, network, variables, W::DefaultDict)
    constraints = []
    _nbus = nbus(network)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        if branch.angmin > -360
            for w1 in W["$(b), $(_nbus + a)"]
                for w2 in W["$(a), $(_nbus + b)"]
                    for w3 in W["$(b), $(a)"]
                        for w4 in W["$(_nbus + b), $(_nbus + a)"]
                            push!(constraints, @constraint(model, w1 - w2 >= tand(branch.angmin) * (w3 + w4)))
                        end
                    end
                end
            end
        end
        if branch.angmax < 360
            for w1 in W["$(b), $(_nbus + a)"]
                for w2 in W["$(a), $(_nbus + b)"]
                    for w3 in W["$(b), $(a)"]
                        for w4 in W["$(_nbus + b), $(_nbus + a)"]
                            push!(constraints, @constraint(model, w1 - w2 <= tand(branch.angmax) * (w3 + w4)))
                        end
                    end
                end
            end
        end
    end
    return constraints
end


function _define_voltage_reference_constraints_no_lc!(model, network, variables, W::DefaultDict)
    constraints = []
    refid = nbus(network) + normid(network, refbus(network).id)
    for w in W["$(refid), $(refid)"]
        push!(constraints, @constraint(model, w == 0))
    end
    return constraints
end


function _define_voltage_limit_constraints_no_lc!(model, network, variables, W::DefaultDict)
    constraints = []
    n = nbus(network)
    for bus in buses(network)
        b = normid(network, bus.id)
        for W1 in W["$b, $b"]
            for W2 in W["$(n + b), $(n + b)"]
                push!(constraints, @constraint(model, W1 + W2 >= bus.vmin^2))
                push!(constraints, @constraint(model, W1 + W2 <= bus.vmax^2))
            end
        end
    end
    return constraints
end
