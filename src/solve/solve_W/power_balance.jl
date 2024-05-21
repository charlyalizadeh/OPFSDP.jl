function _tr_power_balance_real_leq_nbus!(model, nbus, W::LinearAlgebra.Symmetric, Y, bus_id, d)
    return @expression(model,
                       sum(W[j, d] * 1/2 * real(Y[bus_id, j])  +
                           W[nbus + j, d] * (-1/2) * imag(Y[bus_id, j])
                           for j in union(1:bus_id-1, bus_id+1:nbus)) +
                       real(Y[bus_id, bus_id]) * W[d, d])
end


function _tr_power_balance_real_g_nbus!(model, nbus, W::LinearAlgebra.Symmetric, Y, bus_id, d)
    return @expression(model,
                       sum(W[j, d] * 1/2 * imag(Y[bus_id, j])  +
                           W[nbus + j, d] * 1/2 * real(Y[bus_id, j])
                           for j in union(1:bus_id-1, bus_id+1:nbus)) +
                       real(Y[bus_id, bus_id]) * W[d, d])
end


function _tr_power_balance_real!(model, network, W::LinearAlgebra.Symmetric, Y, bus_id, d)
    _nbus = nbus(network)
    if !(d in [bus_id, _nbus + bus_id])
        if d <= _nbus
            return @expression(model,
                               W[bus_id, d] * 1/2 * real(Y[bus_id, d]) +
                               W[_nbus + bus_id, d] * 1/2 * imag(Y[bus_id, d]))
        else
            return @expression(model,
                               W[bus_id, d] * (-1/2) * imag(Y[bus_id, d - _nbus]) +
                               W[_nbus + bus_id, d] * 1/2 * real(Y[bus_id, d - _nbus]))
        end
    elseif d == bus_id
        _tr_power_balance_real_leq_nbus!(model, _nbus, W, Y, bus_id, d)
    else
        _tr_power_balance_real_g_nbus!(model, _nbus, W, Y, bus_id, d)
    end
end


function _tr_power_balance_imag_leq_nbus!(model, nbus, W::LinearAlgebra.Symmetric, Y, bus_id, d)
    return @expression(model,
                       sum(W[j, d] * (-1/2) * imag(Y[bus_id, j])  +
                           W[nbus + j, d] * (-1/2) * real(Y[bus_id, j])
                           for j in union(1:bus_id-1, bus_id+1:nbus)) -
                       imag(Y[bus_id, bus_id]) * W[d, d])
end


function _tr_power_balance_imag_g_nbus!(model, nbus, W::LinearAlgebra.Symmetric, Y, bus_id, d)
    return @expression(model,
                       sum(W[j, d] * 1/2 * real(Y[bus_id, j])  +
                           W[nbus + j, d] * (-1/2) * imag(Y[bus_id, j])
                           for j in union(1:bus_id-1, bus_id+1:nbus)) -
                       imag(Y[bus_id, bus_id]) * W[d, d])
end

function _tr_power_balance_imag!(model, network, W::LinearAlgebra.Symmetric, Y, bus_id, d)
    _nbus = nbus(network)
    if !(d in [bus_id, _nbus + bus_id])
        if d <= _nbus
            return @expression(model,
                               W[bus_id, d] * (-1/2) * imag(Y[bus_id, d]) +
                               W[_nbus + bus_id, d] * 1/2 * real(Y[bus_id, d]))
        else
            return @expression(model,
                               W[bus_id, d] * (-1/2) * real(Y[bus_id, d - _nbus]) +
                               W[_nbus + bus_id, d] * (-1/2) * imag(Y[bus_id, d - _nbus]))
        end
    elseif d == bus_id
        _tr_power_balance_imag_leq_nbus!(model, _nbus, W, Y, bus_id, d)
    else
        _tr_power_balance_imag_g_nbus!(model, _nbus, W, Y, bus_id, d)
    end
end


#function _define_power_balance_constraints!(model, network, variables, W::LinearAlgebra.Symmetric, Y)
#    constraints = []
#    for bus in buses(network)
#        push!(constraints, @constraint(model, sum(bus.load) +
#                                       sum(_tr_power_balance_real!(model, network, W, Y, normid(network, bus.id), d) +
#                                           im * _tr_power_balance_imag!(model, network, W, Y, normid(network, bus.id), d)
#                                           for d in 1:2*nbus(network)) ==
#                                       sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id))))
#    end
#    return constraints
#end

#function _define_power_balance_constraints!(model, network, variables, W::LinearAlgebra.Symmetric, Y)
#    constraints = []
#    n = nbus(network)
#    for bus in buses(network)
#        b = normid(network, bus.id)
#        push!(constraints, @constraint(model, sum(bus.load) +
#                                       sum(real(Y[b, i]) * (W[b, i] + W[n + b, n + i]) for i in 1:n) +
#                                       sum(imag(Y[b, i]) * (W[n + b, i] - W[n + i, b]) for i in union(1:b-1, b+1:n)) -
#                                       im * (
#                                       sum(imag(Y[b, i]) * (W[b, i] + W[n + b, n + i]) for i in 1:n) +
#                                       sum(real(Y[b, i]) * (- W[n + b, i] + W[n + i, b]) for i in union(1:b-1, b+1:n))
#                                            )
#                                       ==
#                                       sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id))))
#    end
#    return constraints
#end

function _define_power_balance_constraints!(model, network, variables, W, Y)
    constraints = []
    for bus in buses(network)
        _psi_real = psi_real(network, bus, Y)
        _psi_imag = psi_imag(network, bus, Y)
        push!(constraints, @constraint(model, sum(bus.load) + trJuMP(model, _psi_real, W) + im * trJuMP(model, _psi_imag, W) == sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id))))
    end
    return constraints
end
