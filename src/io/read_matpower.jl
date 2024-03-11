function _arg_to(lines, pattern)
    i = 1
    while !occursin(pattern, lines[i])
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

function _extract_bus_dict(lines, baseMVA)
    i = _arg_bus(lines) + 1
    bus_dict::Dict{Int, Bus} = Dict()
    order = []

    while !occursin("];", lines[i])
        values = _get_line_values(lines[i])
        bus_dict[values[1]] = Bus(trunc(Int, values[1]),                                # id
                                  complex(values[8], values[9] / baseMVA),              # voltage
                                  complex(values[3] / baseMVA, values[4] / baseMVA),    # load
                                  values[13],                                           # vmin
                                  values[12])                                           # vmax
        push!(order, trunc(Int, values[1]))
        i += 1
    end
    return (bus_dict, order)
end

function _extract_gen_data(lines, baseMVA)
    i = _arg_genbus(lines) + 1
    gen_dict::Dict{Int,Vector{Generator}}=Dict()
    order = []

    while !occursin("];", lines[i])
        values = _get_line_values(lines[i])
        if !(values[1] in keys(gen_dict))
            gen_dict[values[1]] = []
        end
        push!(gen_dict[values[1]], Generator(trunc(Int, values[1]),                             # id
                                             length(gen_dict[values[1]]) + 1,                   # genid
                                             complex(values[2] / baseMVA, values[3] / baseMVA), # power
                                             values[10] / baseMVA,                              # Pmin
                                             values[9] / baseMVA,                               # Pmax
                                             values[5] / baseMVA,                               # Qmin
                                             values[4] / baseMVA)                               # Qmax
             )
        push!(order, trunc(Int, values[1]))
        i += 1
    end
    return (gen_dict, order)
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

        network.buses[bus_id].reactive_cost_type = CostType(trunc(Int, values[1]))
        network.buses[bus_id].reactive_cost_coeff = values[5:end]

        line_nb += 1
        index_dict[order[i]] += 1
    end
end

function _extract_branches_values(bus_dict, values, baseMVA)
    v_src = bus_dict[values[1]].v
    v_dst = bus_dict[values[2]].v
    admittance = inv(complex(values[3], values[4]))
    susceptance = values[5]
    tf_ratio = values[9] == 0 ? 1.0 : values[9]
    tf_ps_angle = values[10]#/ baseMVA
    return v_src, v_dst, admittance, susceptance, tf_ratio, tf_ps_angle
end

function _extract_branches(network, lines, baseMVA)
    i = _arg_branch(lines) + 1

    branches::Vector{Branch} = []
    while !occursin("];", lines[i])
        values = _get_line_values(lines[i])
        v_src, v_dst, admittance, susceptance, tf_ratio, tf_ps_angle = _extract_branches_values(network.buses, values, baseMVA)
       rateA = values[6] == 0 ? Inf : values[6] / baseMVA
       rateB = values[7] == 0 ? Inf : values[7] / baseMVA
       rateC = values[8] == 0 ? Inf : values[8] / baseMVA
        branch = Branch(values[1], # source bus id
                        values[2], # destination bus id
                        admittance,
                        susceptance,
                        tf_ratio,
                        tf_ps_angle,
                        rateA,
                        rateB,
                        rateC
                        )
        push!(branches, branch)
        i += 1
    end
    return branches
end

function read_matpower(path::AbstractString)
    lines = split(read(open(path, "r"), String), '\n')
    network = PowerFlowNetwork(_get_name_matpower(path))

    baseMVA = _extract_baseMVA(lines)
    network.buses, network.buses_order = _extract_bus_dict(lines, baseMVA)
    network.generators, network.generators_order = _extract_gen_data(lines, baseMVA)
    network.branches = _extract_branches(network, lines, baseMVA)
    network.ngen = sum(length(val) for val in values(network.generators))
    _add_gencost_data!(network, lines)

    return network
end
