# Let's n = bus_id
# Return |v_n|^2
function _abs_squared!(model, vvm, bus_id)
	return @expression(model, vvm["real(v$(bus_id))*real(v$(bus_id))"] + vvm["imag(v$(bus_id))*imag(v$(bus_id))"])
end

# Let's n = bus_id1 and d = bus_id2
# Return v_n * conj(v_d)
function _conjugate_mult_real!(model, vvm, bus_id1, bus_id2)
	return @expression(model, vvm["real(v$(bus_id1))*real(v$(bus_id2))"] - vvm["imag(v$(bus_id1))*imag(v$(bus_id2))"])
end

function _conjugate_mult_imag!(model, vvm, bus_id1, bus_id2)
	return @expression(model, vvm["real(v$(bus_id1))*imag(v$(bus_id2))"] + vvm["imag(v$(bus_id1))*real(v$(bus_id2))"] )
end
