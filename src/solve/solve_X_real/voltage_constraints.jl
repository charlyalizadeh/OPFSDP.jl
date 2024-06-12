function _define_voltage_angle_limit_constraints!(model, network, X)
    for branch in branches(network)
        if branch.angmin == 0 && branch.angmax == 0
            continue
        end
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        angmin = branch.angmin
        angmax = branch.angmax
        angmin > -90 && @constraint(model, tan(angmin) * (X["vr($b)vr($a)"] + X["vc($b)vc($a)"]) <= X["vc($b)vr($a)"] - X["vr($b)vc($a)"])
        angmax < 90 && @constraint(model, X["vc($b)vr($a)"] - X["vr($b)vc($a)"] <= tan(angmax) * (X["vr($b)vr($a)"] + X["vc($b)vc($a)"]))
        @constraint(model, X["vr($b)vr($a)"] + X["vc($b)vc($a)"] >= 0)
    end
end


function _define_voltage_limit_constraints!(model, network, variables, X)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model, variables["|v($b)|^2"] >= bus.vmin^2)
        @constraint(model, variables["|v($b)|^2"] <= bus.vmax^2)
        if bus.type == ref
            #@constraint(model, X["vc($b)vc($b)"] == 0)
        end
    end
end
