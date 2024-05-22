function read_network(path::AbstractString)
    ext = splitext(path)
    if ext == ".m"
        return read_matpower(path)
    elseif ext == ".raw"
        return read_rawgo(path)
    end
end
