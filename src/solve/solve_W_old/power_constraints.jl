function _define_branch_power_limit_constraints!(model, network, variables, W, Y)
    constraints = []
    for branch in branches(network)
        if branch.rateA == 0 || isinf(branch.rateA)
            continue
        end
        phi_real = phi_L0_real(network, branch)
        phi_imag = phi_L0_imag(network, branch)
        Sb = branch.rateA * network.buses[branch.from].vmin
        Sa = branch.rateA * network.buses[branch.to].vmin
        push!(constraints,
              @constraint(model,
                          [Sb/2;
                           Sb;
                           [trJuMP(model, phi_real, W), trJuMP(model, phi_imag, W)]] in RotatedSecondOrderCone())
       )

        phi_real = phi_L1_real(network, branch)
        phi_imag = phi_L1_imag(network, branch)
        push!(constraints,
              @constraint(model,
                          [Sa/2;
                           Sa;
                           [trJuMP(model, phi_real, W), trJuMP(model, phi_imag, W)]] in RotatedSecondOrderCone())
       )
    end
    return constraints
end
