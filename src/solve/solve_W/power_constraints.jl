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

function _expression_phi_real_L0(model, network, branch, W::LinearAlgebra.Symmetric)
    n = nbus(network)
    b = normid(network, branch.from)
    a = normid(network, branch.to)
    _yff = yff(branch)
    _yft = yft(branch)
    _yffr = real(_yff)
    _yftr, _yftc = real(_yft), imag(_yft)
    @expression(model,
                _yffr * (W[b, b] + W[n + b, n + b]) +
                _yftr * (W[b, a] + W[n + b, n + a]) +
                _yftc * (W[n + b, a] - W[b, n + a])
               )
end


function _expression_phi_real_L1(model, network, branch, W::LinearAlgebra.Symmetric)
    n = nbus(network)
    b = normid(network, branch.to)
    a = normid(network, branch.from)
    _ytt = ytt(branch)
    _ytf = ytf(branch)
    _yttr = real(_ytt)
    _ytfr, _ytfc = real(_ytf), imag(_ytf)
    @expression(model, -(
                _yttr * (W[b, b] + W[n + b, n + b]) +
                _ytfr * (W[b, a] + W[n + b, n + a]) +
                _ytfc * (W[n + b, a] - W[b, n + a])
                ))
end


function _expression_phi_imag_L0(model, network, branch, W::LinearAlgebra.Symmetric)
    n = nbus(network)
    b = normid(network, branch.from)
    a = normid(network, branch.to)
    _yff = yff(branch)
    _yft = yft(branch)
    _yffc = imag(_yff)
    _yftr, _yftc = real(_yft), imag(_yft)
    @expression(model, (
                _yffc * (W[b, b] + W[n + b, n + b]) +
                _yftc * (W[b, a] + W[n + b, n + a]) +
                _yftr * (-W[n + b, a] + W[b, n + a])
                ))
end


function _expression_phi_imag_L1(model, network, branch, W::LinearAlgebra.Symmetric)
    n = nbus(network)
    b = normid(network, branch.to)
    a = normid(network, branch.from)
    _ytt = ytt(branch)
    _ytf = ytf(branch)
    _yttc = imag(_ytt)
    _ytfr, _ytfc = real(_ytf), imag(_ytf)
    @expression(model, -(
                _yttc * (W[b, b] + W[n + b, n + b]) +
                _ytfc * (W[b, a] + W[n + b, n + a]) +
                _ytfr * (-W[n + b, a] + W[b, n + a])
                ))
end


#function _define_branch_power_limit_constraints!(model, network, variables, W, Y)
#    constraints = []
#    for branch in branches(network)
#        if branch.rateA == 0 || isinf(branch.rateA)
#            continue
#        end
#        Sb = branch.rateA #* network.buses[branch.from].vmin
#        Sa = branch.rateA #* network.buses[branch.to].vmin
#        phi_L0_real = _expression_phi_real_L0(model, network, branch, W)
#        phi_L0_imag = _expression_phi_imag_L0(model, network, branch, W)
#        push!(constraints,
#              @constraint(model,
#                          [Sb/2;
#                           Sb;
#                           [phi_L0_real, phi_L0_imag]] in RotatedSecondOrderCone())
#       )
#
#        phi_L1_real = _expression_phi_real_L1(model, network, branch, W)
#        phi_L1_imag = _expression_phi_imag_L1(model, network, branch, W)
#        push!(constraints,
#              @constraint(model,
#                          [Sa/2;
#                           Sa;
#                           [phi_L1_real, phi_L1_imag]] in RotatedSecondOrderCone())
#       )
#    end
#    return constraints
#end
