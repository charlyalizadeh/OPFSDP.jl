include("compute_current.jl")
include("compute_power.jl")

function arg_to(lines, pattern)
    i = 1
    while !occursin(pattern, lines[i])
        i += 1
    end
    return i
end

function get_line_values(line)
    line = split(line, ';')[1]
    values = split(line, '\t')[2:end]
    return map(x -> parse(Float64, x), values)
end

arg_baseMVA(lines) = arg_to(lines, "mpc.baseMVA")
arg_bus(lines) = arg_to(lines, "mpc.bus")
arg_genbus(lines) = arg_to(lines, "mpc.gen")
arg_branch(lines) = arg_to(lines, "mpc.branch")
arg_gencost(lines) = arg_to(lines, "mpc.gencost")

function extract_baseMVA(lines)
    i = arg_baseMVA(lines)
    return parse(Float64, split(lines[i][15:end], ';')[end - 1])
end

function extract_bus_dict(lines, baseMVA)
    i = arg_bus(lines) + 1
    bus_dict::Dict{Int, Bus} = Dict()

    while !occursin("];", lines[i])
        values = get_line_values(lines[i])
        bus_dict[values[1]] = Bus(trunc(Int, values[1]),
                                  complex(values[8], values[9] / baseMVA),
                                  complex(values[3] / baseMVA, values[4] / baseMVA),
                                  values[13],
                                  values[12])
        i += 1
    end
    return bus_dict
end

function add_gen_data(bus_dict::Dict{Int, Bus}, lines, baseMVA)
    i = arg_genbus(lines) + 1

    while !occursin("];", lines[i])
        values = get_line_values(lines[i])
        bus_dict[values[1]].power = complex(values[2] / baseMVA, values[3] / baseMVA)
        bus_dict[values[1]].Pmin = values[10] / baseMVA
        bus_dict[values[1]].Pmax = values[9] / baseMVA
        bus_dict[values[1]].Qmin = values[5] / baseMVA
        bus_dict[values[1]].Qmax = values[4] / baseMVA
        bus_dict[values[1]].gen = true
        i += 1
    end
end

function add_gencost_data(network, lines)
    line_nb = arg_gencost(lines) + 1

    for bus_id in network.gen_buses_id
        values = get_line_values(lines[line_nb])
        network.buses[bus_id].active_cost_type = CostType(trunc(Int, values[1]))
        network.buses[bus_id].active_cost_coeff = values[5:end]
        line_nb += 1
    end
    if occursin("];", lines[line_nb])
        return
    end
    for bus_id in network.gen_buses_id
        values = get_line_values(lines[line_nb])
        network.buses[bus_id].reactive_cost_type = CostType(trunc(Int, values[1]))
        network.buses[bus_id].reactive_cost_coeff = values[5:end]
        line_nb += 1
    end
end

function extract_branches(bus_dict, lines, baseMVA)
    i = arg_branch(lines) + 1

    branches::Vector{Branch} = []
    while !occursin("];", lines[i])
        values = get_line_values(lines[i])
        currents = compute_current(bus_dict, values, baseMVA)
        powers = compute_power(bus_dict, values, baseMVA)
        branch = Branch(values[1], values[2],
                        currents[1], currents[2],
                        powers[1], powers[2])
        push!(branches, branch)
        i += 1
    end
    return branches
end

function read_matpower(path::AbstractString)
    lines = split(read(open(path, "r"), String), '\n')
    network = PowerFlowNetwork()

    baseMVA = extract_baseMVA(lines)
    bus_dict = extract_bus_dict(lines, baseMVA)
    add_gen_data(bus_dict, lines, baseMVA)
    branches = extract_branches(bus_dict, lines, baseMVA)
    network.buses = [bus_dict[k] for k in sort(collect(keys(bus_dict)))]
    network.branches = branches
    for (i, bus) in enumerate(network.buses)
        if bus.gen
            push!(network.gen_buses_id, i)
        end
    end
    add_gencost_data(network, lines)

    return network
end
