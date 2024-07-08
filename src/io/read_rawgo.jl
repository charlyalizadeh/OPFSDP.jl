module ReadRawGo

import ..OPFSDP: PowerFlowNetwork, Bus, Branch, Generator, BusType, CostType, JSON, PQ

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
    return values[2]
end

function _get_line_values(line; char_pos=[2])
    line_split = split(line, ',')
    values = [i in char_pos ? l : parse(Float64, l) for (i, l) in enumerate(line_split)]
    return values
end


function _extract_bus_dict(lines, baseMVA)
    i = 4
    bus_dict::Dict{Int, Bus} = Dict()
    order = []

    while !occursin("END OF BUS DATA BEGIN LOAD DATA", lines[i])
        values = _get_line_values(lines[i])
        bus_dict[values[1]] = Bus(trunc(Int, values[1]),            # id
                                  PQ,                               # bus type
                                  values[8] * exp(im * values[9]),  # voltage
                                  ComplexF64[],                        # load
                                  values[11],                       # vmin
                                  values[10],                       # vmax
                                  complex(0),                       # shunt admittance
                                  values[3]                         # baseKV
                                 )
        push!(order, trunc(Int, values[1]))
        i += 1
    end
    return bus_dict, order
end

function _add_bus_load!(lines, bus_dict, baseMVA)
    i = 4 + length(bus_dict) + 1

    while !occursin("END OF LOAD DATA BEGIN FIXED SHUNT DATA", lines[i])
        values = _get_line_values(lines[i])
        if values[3] == 0
            continue
        end
        push!(bus_dict[values[1]].load, complex(values[7] / baseMVA, values[8] / baseMVA))
        i += 1
    end
    for (id, bus) in bus_dict
        if isempty(bus_dict[id].load)
            push!(bus_dict[id].load, complex(0))
        end
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

function _extract_gen_data(lines, baseMVA, case_json)
    i = _arg_to(lines, "END OF FIXED SHUNT DATA BEGIN GENERATOR DATA") + 1
    gen_dict::Dict{Int,Vector{Generator}}=Dict()
    order = []
    genid = 1
    cost_dict = Dict()
    for g in case_json["generators"]
        if !(g["bus"] in keys(cost_dict))
            cost_dict[g["bus"]] = Dict()
        end
        cost_dict[g["bus"]][g["id"]] = g["cblocks"]
    end

    while !occursin("END OF GENERATOR DATA BEGIN BRANCH DATA", lines[i])
        values = _get_line_values(lines[i])
        if !(values[1] in keys(gen_dict))
            gen_dict[values[1]] = []
        end
        push!(gen_dict[values[1]], Generator(trunc(Int, values[1]),                             # busid
                                             genid,                                             # genid
                                             length(gen_dict[values[1]]) + 1,                   # genorder
                                             trunc(Int, values[15]),                            # status
                                             complex(values[3] / baseMVA, values[4] / baseMVA), # power
                                             values[18] / baseMVA,                              # Pmin
                                             values[17] / baseMVA,                              # Pmax
                                             values[6] / baseMVA,                               # Qmin
                                             values[5] / baseMVA)                               # Qmax
             )
        id2 = "$(values[2][2])"
        gen_dict[values[1]][end].active_cost_coeff = cost_dict[values[1]][id2]
        gen_dict[values[1]][end].active_cost_type = CostType(3)
        push!(order, trunc(Int, values[1]))
        i += 1
        genid += 1
    end
    return gen_dict, order
end

function _extract_branches(lines, baseMVA)
    i = _arg_to(lines, "END OF GENERATOR DATA BEGIN BRANCH DATA") + 1
    branches::Vector{Branch} = []

    while !occursin("END OF BRANCH DATA BEGIN TRANSFORMER DATA", lines[i])
        values = _get_line_values(lines[i]; char_pos=[3])
        push!(branches, Branch(values[1],                                # srouce bud id
                               values[2],                                # destination bus id
                               values[4],                                # r
                               values[5],                                # x
                               values[6],                                # b
                               1.0,                                      # tf_ratio
                               0.0,                                      # tf_ps_angle
                               values[7] == 0 ? 0 : values[6] / baseMVA, # rateA
                               values[8] == 0 ? 0 : values[7] / baseMVA, # rateB
                               values[9] == 0 ? 0 : values[8] / baseMVA, # rateC
                               -90,                                      # angmin
                               90,                                       # angmax
                              ))
        i += 1
    end
    return branches
end

function read_rawgo(path::AbstractString)
    file = read(open(path, "r"), String)
    lines = split(file, '\n')
    case_json = JSON.parsefile(joinpath(dirname(path), "case.json"))
    network = PowerFlowNetwork()
    baseMVA = _extract_baseMVA(lines)
    network.buses, network.buses_order = _extract_bus_dict(lines, baseMVA)
    _add_bus_load!(lines, network.buses, baseMVA)
    _add_bus_shunt!(lines, network.buses, baseMVA)
    network.generators, network.generators_order = _extract_gen_data(lines, baseMVA, case_json)
    network.branches = _extract_branches(lines, baseMVA)
    return network
end

end
