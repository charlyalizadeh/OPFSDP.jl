module OPFSDP

mutable struct Bus
	id::Int
	v::Complex
	Sl::Complex
	vmin::Float64
	vmax::Float64
	S::Complex
	cost_linear::Float64
	cost_constant::Float64
	Pmin::Float64
	Pmax::Float64
	Qmin::Float64
	Qmax::Float64
	gen::Bool
end

mutable struct Branch
	bus_src::Int
	bus_dst::Int
	isrc::Complex
	idst::Complex
	Ssrc::Complex
	Sdst::Complex
end

mutable struct PowerFlowNetwork
	name::String
	buses::Vector{Bus}
	branches::Vector{Branch}
end

Bus() = Bus(-1, complex(0., 0.), complex(0., 0.), 0., 0., complex(0., 0.), 0., 0., 0., 0., 0., 0., false)
function Bus(id::Int, v::Complex, Sl::Complex, vmin::Float64, vmax::Float64)
	Bus(id, v, Sl, vmin, vmax, complex(0., 0.), 0., 0., 0., 0., 0., 0., false)
end

PowerFlowNetwork() = PowerFlowNetwork("", [], [])


include("io/read_matpower.jl")
export read_matpower

end
