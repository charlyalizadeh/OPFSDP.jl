function get_object_str(object)
	name = string(typeof(object))
	object_fieldnames = sort(collect(map(string, fieldnames(typeof(object)))))
	key_val_str = join(["$f:$(getfield(object, Symbol(f)))" for f in object_fieldnames], ";")
    return "($(name)|$(key_val_str))"
end

function write_decomposition(path::AbstractString, extension::AbstractChordalExtension)
    network = OPFSDP.read_matpower(path)
    name = splitext(splitdir(path)[end])[1]
    cadj = OPFSDP.cholesky_extension(network)
    cliques = OPFSDP.maximal_cliques(cadj)
    cliquetree = OPFSDP.maximal_cliquetree(cliques)
    open("$(name)_$(get_object_str(extension)).txt", "w") do io
        writedlm(io, cadj, ',')
    end
end
