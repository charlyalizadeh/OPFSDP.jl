function _get_power_balance_real_leq_nbus(nbus, Y, bus_id, d)
    arr = []
    for j in union(1:bus_id-1, bus_id+1:nbus)
        push!(arr, [j, d, 1/2 * real(Y[bus_id, j])])
        push!(arr, [nbus + j, d, (-1/2) * imag(Y[bus_id, j])])
    end
    push!(arr, [d, d, real(Y[bus_id, bus_id])])
    return arr
end


function _get_power_balance_real_g_nbus(nbus, Y, bus_id, d)
    arr = []
    for j in union(1:bus_id-1, bus_id+1:nbus)
        push!(arr, [j, d, 1/2 * imag(Y[bus_id, j])])
        push!(arr, [nbus + j, d, 1/2 * real(Y[bus_id, j])])
    end
    push!(arr, [d, d, real(Y[bus_id, bus_id])])
    return arr
end


function _get_power_balance_real(network, Y, bus_id, d)
    _nbus = nbus(network)
    if !(d in [bus_id, _nbus + bus_id])
        if d <= _nbus
            return [[bus_id, d, 1/2 * real(Y[bus_id, d])],
                    [_nbus + bus_id, d, 1/2 * imag(Y[bus_id, d])]]
        else
            return [[bus_id, d, (-1/2) * imag(Y[bus_id, d - _nbus])],
                    [_nbus + bus_id, d, 1/2 * real(Y[bus_id, d - _nbus])]]
        end
    elseif d == bus_id
        return _get_power_balance_real_leq_nbus(_nbus, Y, bus_id, d)
    else
        return _get_power_balance_real_g_nbus(_nbus, Y, bus_id, d)
    end
end


function _get_power_balance_imag_leq_nbus(nbus, Y, bus_id, d)
    arr = []
    for j in union(1:bus_id-1, bus_id+1:nbus)
        push!(arr, [j, d, (-1/2) * imag(Y[bus_id, j])])
        push!(arr, [nbus + j, d, (-1/2) * real(Y[bus_id, j])])
    end
    push!(arr, [d, d, -imag(Y[bus_id, bus_id])])
    return arr
end


function _get_power_balance_imag_g_nbus(nbus, Y, bus_id, d)
    arr = []
    for j in union(1:bus_id-1, bus_id+1:nbus)
        push!(arr, [j, d, 1/2 * real(Y[bus_id, j])])
        push!(arr, [nbus + j, d, (-1/2) * imag(Y[bus_id, j])])
    end
    push!(arr, [d, d, -imag(Y[bus_id, bus_id])])
    return arr
end


function _get_power_balance_imag(network, Y, bus_id, d)
    _nbus = nbus(network)
    if !(d in [bus_id, _nbus + bus_id])
        if d <= _nbus
            return [[bus_id, d, (-1/2) * imag(Y[bus_id, d])],
                    [_nbus + bus_id, d, 1/2 * real(Y[bus_id, d])]]
        else
            return [[bus_id, d, (-1/2) * real(Y[bus_id, d - _nbus])],
                    [_nbus + bus_id, d, (-1/2) * imag(Y[bus_id, d - _nbus])]]
        end
    elseif d == bus_id
        return _get_power_balance_imag_leq_nbus(_nbus, Y, bus_id, d)
    else
        return _get_power_balance_imag_g_nbus(_nbus, Y, bus_id, d)
    end
end

function group_W_index(parts)
    parts_dict = Dict()
    for part in parts
        if part in keys(parts_dict)
            parts_dict[part[1:2]] += part[3]
        else
            parts_dict[part[1:2]] = part[3]
        end
    end
    return [[k..., v] for (k, v) in parts_dict]
end


function _get_power_balance_constraints_coeff(network, Y)
    data = Dict()
    for bus in buses(network)
        real_parts = []
        imag_parts = []
        for d in 1:2*nbus(network)
            append!(real_parts, _get_power_balance_real(network, Y, normid(network, bus.id), d))
            append!(imag_parts, _get_power_balance_imag(network, Y, normid(network, bus.id), d))
        end
        real_parts = group_W_index(real_parts)
        imag_parts = group_W_index(imag_parts)
        filter!(part -> part[3] != 0, real_parts)
        filter!(part -> part[3] != 0, imag_parts)
        total_load = sum(bus.load)
        data[bus.id] = Dict("real" => real_parts,
                            "imag" => imag_parts,
                            "load" => Dict("real" => real(total_load), "imag" => imag(total_load)))
    end
    return data
end


function save_power_balance_constraints_coeff(network, path)
    Y = admittance_matrix_W(network)
    data = _get_power_balance_constraints_coeff(network, Y)
    open(path, "w") do f
        JSON.print(f, data)
    end
end


function load_power_balance_constraints!(model, network, W::LinearAlgebra.Symmetric, variables, path)
    constraints = []
    data = JSON.parsefile(path)
    for bus in buses(network)
        push!(constraints, @constraint(model,
                                       (data["$(bus.id)"]["load"]["real"] + data["$(bus.id)"]["load"]["imag"] * im) +
                                       sum(W[trunc.(Int, c[1:2])...] * c[3] for c in data["$(bus.id)"]["real"]) +
                                       sum(W[trunc.(Int, c[1:2])...] * c[3] * im for c in data["$(bus.id)"]["imag"]) ==
                                       sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id))))
    end
    return constraints
end


function load_power_balance_constraints!(model, network, W::DefaultDict, variables, path)
    constraints = []
    data = JSON.parsefile(path)
    for bus in buses(network)
        push!(constraints, @constraint(model,
                                       (data["$(bus.id)"]["load"]["real"] + data["$(bus.id)"]["load"]["imag"] * im) +
                                       sum(W[join(trunc.(Int, c[1:2]), ", ")] * c[3] for c in data["$(bus.id)"]["real"]) +
                                       sum(W[join(trunc.(Int, c[1:2]), ", ")] * c[3] for c in data["$(bus.id)"]["imag"]) * im ==
                                       sum(variables["S_$(gen.genid)"] for gen in generators(network, bus.id))))
    end
    return constraints
end
