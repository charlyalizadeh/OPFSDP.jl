function _define_voltage_limit_constraints!(model, network, vvm)
    for (id, bus) in network.buses
		@constraint(model, vvm["real(v$(id))*real(v$(id))"] + vvm["imag(v$(id))*imag(v$(id))"] <= bus.vmax^2)
		@constraint(model, vvm["real(v$(id))*real(v$(id))"] + vvm["imag(v$(id))*imag(v$(id))"] >= bus.vmin^2)
	end
end
