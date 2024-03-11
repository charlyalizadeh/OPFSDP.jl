function display_objective_generator(gen)
    costs = gen.active_cost_coeff
    for (j, cost) in enumerate(costs)
        if j == length(costs)
            print("$(cost)")
        else
            power = length(costs) - j
            print("$(cost)\\cdot \\Re(S_{$(gen.id)($(gen.genid))})^{$(power)}")
            if j != length(costs)
                print(" + ")
            end
        end
    end
end

function display_objective_function(network)
	print("\\min\\quad & ")
    for (i, gen_array) in enumerate(values(network.generators))
        for (j, gen) in enumerate(gen_array)
            display_objective_generator(gen)
            if j != length(gen_array)
                print(" + ")
            end
        end
        if i != length(values(network.generators))
			print(" + ")
		end
	end
	println("& (objective)\\\\")
end

function display_power_balance_bus(network, bus)
	print("& S_$(bus.id) = $(bus.load) + ")
	branches_out = OPFSDP.get_branches_out(network, bus.id)
	for (i, branch) in enumerate(branches_out)
		powers = OPFSDP.branch_compute_power_origin(branch)
		if i > 1 && real(powers[1]) >= 0
			print(" + ")
		end
		dst_id = network.buses[branch.dst].id
		print("$(powers[1])\\cdot |v_$(bus.id)|^2")
		if real(powers[2]) >= 0
			print(" + ")
		end
		print("$(powers[2])\\cdot v_$(bus.id)\\cdot \\overline{v_$(dst_id)}")
	end
	branches_in = OPFSDP.get_branches_in(network, bus.id)
	for (i, branch) in enumerate(branches_in)
		powers = OPFSDP.branch_compute_power_destination(branch)
		if i == 1 && real(powers[1]) >= 0
			print(" + ")
		end
		src_id = network.buses[branch.src].id
		print("$(powers[1])\\cdot \\overline{v_$(src_id)}\\cdot v_$(bus.id) - $(powers[2])\\cdot |v_$(bus.id)|^2")
	end
	println("& (power\\_balance)\\\\")
end

function display_power_balance(network)
    for (id, bus) in network.buses
		display_power_balance_bus(network, bus)
		println("\n")
	end
    for (id, bus) in network.buses
        if id in keys(network.generators)
			continue
		end
		println("& S_$(bus.id) = 0 & (power\\_balance\\_nogen)\\\\")
	end
end

function display_power_limit(network)
    for gen in generators(network)
        println("& $(gen.Pmin) \\leq Re(S_{$(gen.id)($(gen.genid))}) \\leq $(gen.Pmax) & (power\\_limit)\\\\")
	end
    for gen in generators(network)
        println("& $(gen.Qmin) \\leq Im(S_{$(gen.id)($(gen.genid))}) \\leq $(gen.Qmax) & (power\\_limit)\\\\")
	end
end

function display_voltage_limit(network)
    for (id, bus) in network.buses
		println("& $(bus.vmin^2) \\leq |v_$(id)|^2 \\leq $(bus.vmax^2) & (voltage\\_limit)\\\\")
	end
end

function display_branch_current_limit(network)
	for branch in network.branches
		currents = OPFSDP.branch_compute_current_origin(branch)
		println("& |$(currents[1]) \\cdot v_$(branch.src)")
		if real(currents[2]) >= 0
			print(" + ")
		end
		print("$(currents[2]) \\cdot v_$(branch.dst)| \\leq $(branch.rateA) & (branch\\_current\\_limit)\\\\")
	end
end

function display_opf(network)
	println("\$\$ \\begin{aligned}")
	display_objective_function(network)
	print("\\text{Subject to}\\quad")
	display_power_balance(network)
	display_power_limit(network)
	display_voltage_limit(network)
	display_branch_current_limit(network)
	println()
	print("\\end{aligned} \$\$")
end
