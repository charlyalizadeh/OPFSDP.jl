module ReadRawGo

import ..OPFSDP: PowerFlowNetwork, Bus, Branch, Generator, BusType, CostType

export read_rawgo


function _arg_to(lines, pattern)
    i = 1
    while i < length(lines) && !occursin(pattern, lines[i])
        i += 1
    end
    return i
end

function _extract_baseMVA(lines)
    values = map(x -> parse(Float64, x), split(lines[1], ','))
    return values[1]
end


function _get_line_values(line)
    line_split = split(line, ',')
    values = [i == 2 ? l: parse(Float64, l) for (i, l) in enumerate(line_split)]
    return values
end

function _extract_bus_dict(lines)
    i = 4
    bus_dict::Dict{Int, Bus} = Dict()
    order = []

    while !occursin("END OF BUS DATA BEGIN LOAD DATA", lines[i])
        values = _get_line_values(lines[i])
        bus_dict[values[1]] = Bus(trunc(Int, values[1]),            # id
                                  PQ,                               # bus type
                                  values[8] * exp(im * values[9]),  # voltage
                                  [],                                # load
                                  values[11],                       # vmin
                                  values[10],                       # vmax
                                  0,                                # shunt admittance
                                  value[3]                          # baseKV
                                 )
        push!(order, trunc(Int, values[1]))
        i += 1
    end
    return bus_dict, order
end

function _add_bus_load!(lines, bus_dict, baseMVA)
    i = 4 + length(bus_dict)

    while !occursin("END OF LOAD DATA BEGIN FIXED SHUNT DATA", lines[i])
        values = _get_line_values(lines[i])
        if values[3] == 0
            continue
        end
        push!(bus_dict[values[1]].load, complex(values[7] / baseMVA, values[8] / baseMVA))
        i += 1
    end
end


function _add_bus_shunt!(lines, bus_dict, baseMVA)
    i = _arg_to(lines, "END OF LOAD DATA BEGIN FIXED SHUNT DATA") + 1

    while !occursin("END OF FIXED SHUNT DATA BEGIN GENERATOR DATA", lines[i])
        values = _get_line_values(lines[i])
        bus_dict[values[1]].shunt_admittance = complex(values[4] / baseMVA, values[5] / baseMVA)
        i += 1
    end
end


function _extract_gen_data(lines, baseMVA)
    i = _arg_to(lines, "END OF FIXED SHUNT DATA BEGIN GENERATOR DATA") + 1
    gen_dict::Dict{Int,Vector{Generator}}=Dict()
    order = []
    genid = 1

    while !occursin("", lines[i])
        values = _get_line_values(lines)
        if !(values[1] in keys(gen_dict))
            gen_dict[values[1]] = []
        end
        push!(gen_dict[values[1]], Generator(trunc(Int, values[1]),                             # busid
                                             genid,                                             # genid
                                             length(gen_dict[values[1]]) + 1,                   # genorder
                                             complex(values[3] / baseMVA, values[4] / baseMVA), # power
                                             values[18] / baseMVA,                              # Pmin
                                             values[17] / baseMVA,                              # Pmax
                                             values[6] / baseMVA,                               # Qmin
                                             values[5] / baseMVA)                               # Qmax
             )
        push!(order, trunc(Int, values[1]))
        i += 1
        genid += 1
    end
    return gen_dict, order
end


function _add_gencost_data!(network, case_dict)
    line_nb = _arg_gencost(lines) + 1
    order = network.generators_order
    index_dict = Dict(k => 1 for k in order)

    for i in 
end


function read_rawgo(path::AbstractPath)
    file = read(open(path, "r"), String)
    lines = split(file, '\n')
    network = PowerFlowNetwork()
    baseMVA = extract_baseMVA(lines)
    network.buses, network.buses_order = _extract_bus_dict(lines, baseMVA; convert_load=convert_load)
    _add_bus_load!(lines, bus_dict, baseMVA)
    _add_bus_shunt!(lines, bus_dict, baseMVA)
    network.generators, network.generators_order = _extract_gen_data(lines, baseMVA)
    return network
end

end
