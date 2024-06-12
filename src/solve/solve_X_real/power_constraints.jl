function _sum_branch_flow_real!(model, network, variables, bus_id)
    return @expression(model, sum(variables["real(S_$(normid(network, bus_id))_$(normid(network, b.from == bus_id ? b.to : b.from)))"] for b in branches(network, bus_id)))
end

function _sum_branch_flow_imag!(model, network, variables, bus_id)
    return @expression(model, sum(variables["imag(S_$(normid(network, bus_id))_$(normid(network, b.from == bus_id ? b.to : b.from)))"] for b in branches(network, bus_id)))
end

function _define_power_balance_constraints!(model, network, variables, X)
    for bus in buses(network)
        b = normid(network, bus.id)
        @constraint(model,
                    _sum_branch_flow_real!(model, network, variables, bus.id) +
                    real(bus.load[1]) ==
                    -real(bus.shunt_admittance) * variables["|v($b)|^2"] +
                    sum(variables["real(S_$(gen.genid))"] for gen in generators(network, bus.id)))
        @constraint(model,
                    _sum_branch_flow_imag!(model, network, variables, bus.id) +
                    imag(bus.load[1]) ==
                    imag(bus.shunt_admittance) * variables["|v($b)|^2"] +
                    sum(variables["imag(S_$(gen.genid))"] for gen in generators(network, bus.id)))
    end
end


function _define_branch_current_flow_constraints!(model, network, variables, X, Y)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        if branch.rateA != 0 && !isinf(branch.rateA)
            @constraint(model,
                        abs2(Y["Yff"][b, a]) * variables["|v($b)|^2"] +
                        abs2(Y["Yft"][b, a]) * variables["|v($a)|^2"] + 2 *
                        (real(Y["Yff"][b, a]) * real(Y["Yft"][b, a]) * X["vr($b)vr($a)"] +
                         imag(Y["Yff"][b, a]) * imag(Y["Yft"][b, a]) * X["vc($b)vc($a)"] +
                         real(Y["Yff"][b, a]) * real(Y["Yft"][b, a]) * X["vc($b)vc($a)"] +
                         imag(Y["Yff"][b, a]) * imag(Y["Yft"][b, a]) * X["vr($b)vr($a)"] -
                         real(Y["Yff"][b, a]) * imag(Y["Yft"][b, a]) * X["vr($b)vc($a)"] -
                         imag(Y["Yff"][b, a]) * real(Y["Yft"][b, a]) * X["vc($b)vr($a)"] +
                         real(Y["Yff"][b, a]) * imag(Y["Yft"][b, a]) * X["vc($b)vr($a)"] +
                         imag(Y["Yff"][b, a]) * real(Y["Yft"][b, a]) * X["vr($b)vc($a)"]) <= branch.rateA^2
                       )
            @constraint(model,
                        abs2(Y["Ytf"][b, a]) * variables["|v($b)|^2"] +
                        abs2(Y["Ytt"][b, a]) * variables["|v($a)|^2"] + 2 *
                        (real(Y["Ytf"][b, a]) * real(Y["Ytt"][b, a]) * X["vr($b)vr($a)"] +
                         imag(Y["Ytf"][b, a]) * imag(Y["Ytt"][b, a]) * X["vc($b)vc($a)"] +
                         real(Y["Ytf"][b, a]) * real(Y["Ytt"][b, a]) * X["vc($b)vc($a)"] +
                         imag(Y["Ytf"][b, a]) * imag(Y["Ytt"][b, a]) * X["vr($b)vr($a)"] -
                         real(Y["Ytf"][b, a]) * imag(Y["Ytt"][b, a]) * X["vr($b)vc($a)"] -
                         imag(Y["Ytf"][b, a]) * real(Y["Ytt"][b, a]) * X["vc($b)vr($a)"] +
                         real(Y["Ytf"][b, a]) * imag(Y["Ytt"][b, a]) * X["vc($b)vr($a)"] +
                         imag(Y["Ytf"][b, a]) * real(Y["Ytt"][b, a]) * X["vr($b)vc($a)"]) <= branch.rateA^2
                       )
        end
    end
end


function _define_branch_power_flow_constraints!(model, network, variables, X, Y)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        c = @constraint(model, variables["real(S_$(b)_$(a))"] == (real(Y["Yff"][b, a]) * variables["|v($b)|^2"] +
                                                              real(Y["Yft"][b, a]) * (X["vr($b)vr($a)"] + X["vc($b)vc($a)"]) +
                                                              imag(Y["Yft"][b, a]) * (X["vc($b)vr($a)"] - X["vr($b)vc($a)"])))
        println("real(S_$(b)_$(a)) = $(real(Y["Yff"][b, a])) * (X[vr($b)vr($b)] + X[vc($b)vc($b)]) + $(real(Y["Yft"][b, a])) * (X[vr($b)vr($a)] + X[vc($b)vc($a)]) + $(imag(Y["Yft"][b, a])) * (X[vc($b)vr($a)] - X[vr($b)vc($a)])")
        println("real(S_$(b)_$(a)) = $(real(Y["Yff"][b, a])) * $(variables["|v($b)|^2"]) + $(real(Y["Yft"][b, a])) * ($(X["vr($b)vr($a)"]) + $(X["vc($b)vc($a)"])) + $(imag(Y["Yft"][b, a])) * ($(X["vc($b)vr($a)"]) - $(X["vr($b)vc($a)"]))")
        #if (b == 1 && a == 2)
        #    println(c)
        #end
        @constraint(model, variables["imag(S_$(b)_$(a))"] == (-imag(Y["Yff"][b, a]) * variables["|v($b)|^2"] +
                                                               real(Y["Yft"][b, a]) * (X["vc($b)vr($a)"] - X["vr($b)vc($a)"]) -
                                                               imag(Y["Yft"][b, a]) * (X["vr($b)vr($a)"] + X["vc($b)vc($a)"])))
        @constraint(model, variables["real(S_$(a)_$(b))"] == (real(Y["Ytt"][b, a]) * variables["|v($a)|^2"] +
                                                              real(Y["Ytf"][b, a]) * (X["vr($a)vr($b)"] + X["vc($a)vc($b)"]) +
                                                              imag(Y["Ytf"][b, a]) * (X["vc($a)vr($b)"] - X["vr($a)vc($b)"])))
        @constraint(model, variables["imag(S_$(a)_$(b))"] == (-imag(Y["Ytt"][b, a]) * variables["|v($a)|^2"] +
                                                               real(Y["Ytf"][b, a]) * (X["vc($a)vr($b)"] - X["vr($a)vc($b)"]) -
                                                               imag(Y["Ytf"][b, a]) * (X["vr($a)vr($b)"] + X["vc($a)vc($b)"])))
    end
end
