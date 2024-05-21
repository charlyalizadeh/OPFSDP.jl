function save_W_model(network)
    model, variables, constraints = build_model(network)
    write_to_file(model, "$(network.name).cbf")
end

function load_W_model(path)
     model = read_from_file(path)
     return model
end
