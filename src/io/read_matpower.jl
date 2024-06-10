module ReadMatpower

import ..OPFSDP: PowerFlowNetwork, Bus, Branch, Generator, BusType, CostType, refbus

export read_matpower

function _arg_to(lines, pattern)
    i = 1
    while i < length(lines) && !occursin(pattern, lines[i])
        i += 1
    end
    return i
end

function _get_line_values(line)
    line = split(line, ';')[1]
    values = split(line, '\t')[2:end]
    return map(x -> parse(Float64, x), values)
end

_arg_baseMVA(lines) = _arg_to(lines, "mpc.baseMVA")
_arg_bus(lines) = _arg_to(lines, "mpc.bus")
_arg_genbus(lines) = _arg_to(lines, "mpc.gen")
_arg_branch(lines) = _arg_to(lines, "mpc.branch")
_arg_gencost(lines) = _arg_to(lines, "mpc.gencost")

function _get_name_matpower(path)
    return splitext(splitdir(path)[end])[1]
end

function _extract_baseMVA(lines)
    i = _arg_baseMVA(lines)
    return parse(Float64, split(lines[i][15:end], ';')[end - 1])
end

function _extract_bus_dict(lines, baseMVA; convert_load=false)
    i = _arg_bus(lines) + 1
    bus_dict::Dict{Int, Bus} = Dict()
    order = []

    while !occursin("];", lines[i])
        values = _get_line_values(lines[i])
        if convert_load
            values[3] = values[3] / 1e3
            values[4] = values[4] / 1e3
        end
        bus_dict[values[1]] = Bus(trunc(Int, values[1]),                                  # id
                                  BusType(trunc(Int, values[2])),                         # bus type
                                  values[8] * exp(im * values[9]),                        # voltage
                                  [complex((values[3]) / baseMVA, (values[4]) / baseMVA)],# load
                                  values[13],                                             # vmin
                                  values[12],                                             # vmax
                                  complex(values[5] / baseMVA, values[6] / baseMVA),      # shunt admittance
                                  values[10]                                              # baseKV
                                 )
        push!(order, trunc(Int, values[1]))
        i += 1
    end
    return bus_dict, order
end

function _extract_gen_data(lines, baseMVA)
    i = _arg_genbus(lines) + 1
    gen_dict::Dict{Int,Vector{Generator}}=Dict()
    order = []
    genid = 1

    while !occursin("];", lines[i])
        values = _get_line_values(lines[i])
        if !(values[1] in keys(gen_dict))
            gen_dict[values[1]] = []
        end
        push!(gen_dict[values[1]], Generator(trunc(Int, values[1]),                             # busid
                                             genid,                                             # genid
                                             length(gen_dict[values[1]]) + 1,                   # genorder
                                             values[8] > 0 ? 1 : 0,                             # status
                                             complex(values[2] / baseMVA, values[3] / baseMVA), # power
                                             values[10] / baseMVA,                              # Pmin
                                             values[9] / baseMVA,                               # Pmax
                                             values[5] / baseMVA,                               # Qmin
                                             values[4] / baseMVA)                               # Qmax
             )
        push!(order, trunc(Int, values[1]))
        i += 1
        genid += 1
    end
    return gen_dict, order
end

function _add_gencost_data!(network, lines)
    line_nb = _arg_gencost(lines) + 1
    order = network.generators_order
    index_dict = Dict(k => 1 for k in order)

    for i in 1:network.ngen
        values = _get_line_values(lines[line_nb])

        ncost = values[4]
        network.generators[order[i]][index_dict[order[i]]].active_cost_type = CostType(trunc(Int, values[1]))
        network.generators[order[i]][index_dict[order[i]]].active_cost_coeff = [v #==* 10^(2 * (ncost - i))==# for (i, v) in enumerate(values[5:end])]

        line_nb += 1
        index_dict[order[i]] += 1
    end
    if occursin("];", lines[line_nb])
        return
    end

    index_dict = Dict(k => 1 for k in order)
    for i in 1:network.ngen
        values = _get_line_values(lines[line_nb])

        ncost = values[4]
        network.generators[order[i]][index_dict[order[i]]].reactive_cost_type = CostType(trunc(Int, values[1]))
        network.generators[order[i]][index_dict[order[i]]].reactive_cost_coeff = [v #==* 10^(2 * (ncost - i))==# for (i, v) in enumerate(values[5:end])]

        line_nb += 1
        index_dict[order[i]] += 1
    end
end

function _extract_branches_values(bus_dict, values, baseMVA; convert_r_x=false, factor=nothing)
    if convert_r_x
        values[3] /= factor
        values[4] /= factor
    end
    admittance = inv(complex(values[3], values[4]))
    susceptance = values[5]
    tf_ratio = values[9] == 0 ? 1.0 : values[9]
    if values[3] == 0 && values[4] == 0 && values[5] == 0
        tf_ratio = abs(bus_dict[values[1]].v) / abs(bus_dict[values[2]].v)
    end
    tf_ps_angle = values[10]
    return v_from, v_to, admittance, susceptance, tf_ratio, tf_ps_angle
end

function _extract_branches(network, lines, baseMVA; convert_r_x=false, factor=nothing)
    i = _arg_branch(lines) + 1

    branches::Vector{Branch} = []
    while !occursin("];", lines[i])
        values = _get_line_values(lines[i])
        ang = values[10]
        angmin = values[12]
        angmax = values[13]
        if angmin == 0 || angmin == -360
            angmin = -90
        end
        if angmax == 0 || angmax == 360
            angmax = 90
        end
        ang = pi * ang / 180
        angmin = pi * angmin / 180
        angmax = pi * angmax / 180
        branch = Branch(values[1],                                # source bus id
                        values[2],                                # destination bus id
                        values[3],                                # r
                        values[4],                                # x
                        values[5],                                # b
                        values[9] == 0 ? 1.0 : values[9],         # tf_ratio
                        ang,                                      # tf_ps_angle
                        values[6] == 0 ? 0 : values[6] / baseMVA, # rateA
                        values[7] == 0 ? 0 : values[7] / baseMVA, # rateB
                        values[8] == 0 ? 0 : values[8] / baseMVA, # rateC
                        angmin,                                   # angmin
                        angmax                                    # angmax
                       )
        push!(branches, branch)
        i += 1
    end
    return branches
end

function check_convert_load(file)
    return occursin("Vbase = mpc.bus(1, BASE_KV) * 1e3;", file)# && !occursin("%Vbase = mpc.bus(1, BASE_KV) * 1e3;", file)
end

function check_convert_r_x(file)
    return occursin("mpc.bus(:, [PD, QD]) = mpc.bus(:, [PD, QD]) / 1e3;", file)# && !occursin("%mpc.bus(:, [PD, QD]) = mpc.bus(:, [PD, QD]) / 1e3;", file))
end


function read_matpower(path::AbstractString)
    file = read(open(path, "r"), String)
    convert_load = check_convert_load(file)
    convert_r_x = check_convert_r_x(file)
    factor = nothing
    lines = split(file, '\n')
    filter!(l -> !startswith(lstrip(l),'%'), lines)
    network = PowerFlowNetwork(_get_name_matpower(path))

    baseMVA = _extract_baseMVA(lines)
    network.Sbase = float(baseMVA)
    network.buses, network.buses_order = _extract_bus_dict(lines, baseMVA; convert_load=convert_load)
    if convert_r_x
        vbase = refbus(network).baseKV * 1e3
        sbase = baseMVA * 1e6
        factor = vbase^2 / sbase
    end
    network.generators, network.generators_order = _extract_gen_data(lines, baseMVA)
    network.branches = _extract_branches(network, lines, baseMVA; convert_r_x=convert_r_x, factor=factor)
    network.ngen = sum(length(val) for val in values(network.generators))
    if occursin("mpc.gencost", file)
        _add_gencost_data!(network, lines)
    end

    return network
end

end
