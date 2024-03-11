function extract_baseMVA(lines)
    values = map(x -> parse(Float64, x), split(lines[1], ','))
    return values[1]
end


function get_bus_line_values(line)
    line_split = split(line, ',')
    values = [i == 2 ? l: parse(Float64, l) for (i, l) in enumerate(line_split)]
    return values
end

function extract_bus_voltage(lines, baseMVA)
    i = 4
    bus_dict::Dict{Int, Bus} = Dict()

    while !occursin("END OF BUS DATA BEGIN LOAD DATA", lines[i])
        values = get_bus_line_values(lines[i])
        bus_dict[values[1]] = Bus(trunc(Int, values[1]), complex(values[8], values[9] / baseMVA))
        i += 1
    end
end

function extract_bus_demand(lines, bus_dict)

end

function read_matpower(path::AbstractPath)
    lines = split(read(open(path, "r"), String), '\n')
    network = PowerFlowNetwork()
    baseMVA = extract_baseMVA(lines)


    return network
end
