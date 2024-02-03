module OPFSDP

@enum CostType begin
    quadratic = 1
    piecewise_linear = 2
end

mutable struct Bus
	id::Int
	v::Complex
	load::Complex
	vmin::Float64
	vmax::Float64
	power::Complex
	Pmin::Float64
	Pmax::Float64
	Qmin::Float64
	Qmax::Float64
    active_cost_coeff::Vector{Float64}
    reactive_cost_coeff::Vector{Float64}
    cost_type::CostType
	gen::Bool

    function Bus(id::Int=-1,
                 v::Complex=complex(0., 0.), load::Complex=complex(0., 0.), vmin::Float64=0., vmax::Float64=0.,
                 power::Complex=complex(0., 0.), Pmin::Float64=0., Pmax::Float64=0., Qmin::Float64=0., Qmax::Float64=0.,
                 active_cost_coeff::Vector{Float64}=Float64[], reactive_cost_coeff::Vector{Float64}=Float64[], cost_type::CostType=quadratic,
                 gen::Bool=false)
        new(id, v, load, vmin, vmax, power, Pmin, Pmax, Qmin, Qmax, active_cost_coeff, reactive_cost_coeff, cost_type, gen)
    end
end

mutable struct Branch
	bus_src::Int
	bus_dst::Int
	isrc::Complex
	idst::Complex
	power_src::Complex
	power_dst::Complex
end

mutable struct PowerFlowNetwork
	name::String
	buses::Vector{Bus}
	branches::Vector{Branch}

    PowerFlowNetwork(name::String="", buses::Vector{Bus}=Bus[], branches::Vector{Branch}=Branch[]) = new(name, buses, branches)
end



include("io/read_matpower.jl")
export read_matpower

end
