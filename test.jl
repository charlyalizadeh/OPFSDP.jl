include("src/OPFSDP.jl")
using JuMP
using JSON
using SparseArrays
using Printf

#OPFSDP.display_objective_function(network)
#print(json(network,4))
#bus = network.buses[findfirst(b -> b.id == 1, network.buses)]
#OPFSDP.display_opf(network)
#println(JuMP.latex_formulation(model))
#println(model)
#

function display_network_json(name)
    network = OPFSDP.read_matpower("data/MATPOWER/$name.m")
    print(json(network,4))
end

function display_network_cholesky_latex(name)
    network = OPFSDP.read_matpower("data/MATPOWER/$name.m")
    cadj = OPFSDP.cholesky_extension(network)
    cliques = OPFSDP.maximal_cliques(cadj)
    cliquetree = OPFSDP.maximal_cliquetree(cliques)
    model = OPFSDP.solve!(network, cliques, cliquetree)
    println(JuMP.latex_formulation(model))
end

function display_power_value(network, model)
    for (id, bus) in network.buses
        val = JuMP.value(JuMP.variable_by_name(model, "real(S_$(bus.id))")) + im * JuMP.value(JuMP.variable_by_name(model, "imag(S_$(bus.id))"))
        println("(model) S_$(bus.id) = $(val)")
        if bus.id in keys(network.generators)
            gen = network.generators[bus.id][1]
            println("(netwk) S_$(bus.id) = $(gen.power)")
        else
            println("(netwk) S_$(bus.id) = 0 + 0im")
        end
        println("-----------------------------------")
    end
end

function display_voltage_value(network, model, cliques)
    for (clique_id, clique) in enumerate(cliques)
        for i in 1:length(clique)*2
            for j in 1:length(clique)*2
                x = min(i, j)
                y = max(i, j)
                variable = JuMP.variable_by_name(model, "clique_$(clique_id)[$x,$y]")
                value = JuMP.value(variable)
                @printf "%+.2f " value
            end
            println()
        end
        for i in 1:length(clique)*2
            for j in 1:length(clique)*2
                x = min(i, j)
                y = max(i, j)
                variable = JuMP.variable_by_name(model, "clique_$(clique_id)[$x,$y]")
                print(variable)
            end
            println()
        end
    end
    println("-------------------------------")
end

function solve_network(name)
    network = OPFSDP.read_matpower("data/MATPOWER/$name.m")
    cadj = OPFSDP.cholesky_extension(network)
    cliques = OPFSDP.maximal_cliques(cadj)
    cliquetree = OPFSDP.maximal_cliquetree(cliques)

    model = OPFSDP.solve!(network, cliques, cliquetree)
    println("CLIQUES: $(cliques)")
    println(model)
    display_power_value(network, model)
    display_voltage_value(network, model, cliques)

    rates = [b.rateA for b in network.branches]
    println("RATE: $(rates)")
    println("IS SOLVED AND FEASIBLE: $(JuMP.is_solved_and_feasible(model))")
    println("STATUS: $(JuMP.termination_status(model))")
    println("OBJECTIVE: $(JuMP.objective_value(model))")
end

function display_network_rate()
    for path in readdir("data/MATPOWER"; join = true)
        try
            network = OPFSDP.read_matpower(path)
            rates = [b.rateA for b in network.branches]
            println("$(network.name) rate only 0: $(all(rates .== 0))")
        catch e
            println("Couldn't parse $(path)")
        end
    end
end

solve_network("case14")
