@enum CostType begin
    piecewise_linear = 1
    quadratic = 2
end

@enum BusType begin
    PQ = 1
    PV = 2
    ref = 3
    isolated = 4
end

mutable struct Bus
	id::Int
    type::BusType
	v::Complex
    load::Vector{ComplexF64}
	vmin::Float64
	vmax::Float64
    shunt_admittance::Complex
    baseKV::Float64

    function Bus(id::Int=-1, type::BusType=1, v::Complex=complex(0., 0.), load::Vector{ComplexF64}=[], vmin::Float64=0., vmax::Float64=0., shunt_admittance::Complex=complex(0., 0.), baseKV::Float64=0)
		new(id, type, v, load, vmin, vmax, shunt_admittance, baseKV)
    end
end

mutable struct Generator
	busid::Int
    genid::Int
    genorder::Int
	power::Complex
	Pmin::Float64
	Pmax::Float64
	Qmin::Float64
	Qmax::Float64
    active_cost_coeff::Vector{Float64}
    reactive_cost_coeff::Vector{Float64}
    active_cost_type::Union{CostType,Nothing}
    reactive_cost_type::Union{CostType,Nothing}

	function Generator(id::Int, genid::Int, genorder::Int,
                       power::Complex=complex(0., 0.),
                       Pmin::Float64=0., Pmax::Float64=0.,
                       Qmin::Float64=0., Qmax::Float64=0.,
					   active_cost_coeff::Vector{Float64}=Float64[], reactive_cost_coeff::Vector{Float64}=Float64[],
                       active_cost_type::Union{CostType,Nothing}=nothing, reactive_cost_type::Union{CostType,Nothing}=nothing)
		new(id, genid, genorder, power, Pmin, Pmax, Qmin, Qmax, active_cost_coeff, reactive_cost_coeff, active_cost_type, reactive_cost_type)
	end
end

mutable struct Branch
	from::Int
	to::Int
    r::Float64
    x::Float64
    b::Float64
	tf_ratio::Float64
	tf_ps_angle::Float64
	rateA::Float64
	rateB::Float64
	rateC::Float64
    angmin::Float64
    angmax::Float64
end
Base.copy(b::Branch) = Branch(b.from, b.to, b.r, b.x, b.b, b.tf_ratio, b.tf_ps_angle, b.rateA, b.rateB, b.rateC, b.angmin, b.angmax)

mutable struct PowerFlowNetwork
	name::String
	buses::Dict{Int,Bus}
    buses_order::Vector{Int}
	branches::Vector{Branch}
    generators::Dict{Int,Vector{Generator}}
    generators_order::Vector{Int}
    ngen::Int

    function PowerFlowNetwork(name::String="",
                              buses::Dict{Int,Bus}=Dict{Int,Bus}(),
                              buses_order::Vector{Int}=Int[],
                              branches::Vector{Branch}=Branch[],
                              generators::Dict{Int,Vector{Generator}}=Dict{Int,Vector{Generator}}(),
                              generators_order::Vector{Int}=Int[],
                              ngen::Int=0)
        new(name, buses, buses_order, branches, generators, generators_order, ngen)
    end
end

generators(network::PowerFlowNetwork) = vcat([gen for gen in values(network.generators)]...)
function generators(network::PowerFlowNetwork, bus_id)
    if bus_id in keys(network.generators)
        return network.generators[bus_id]
    end
    return []
end
buses(network::PowerFlowNetwork) = collect(values(network.buses))
branches(network::PowerFlowNetwork) = network.branches
branches(network::PowerFlowNetwork, bus_id) = [b for b in network.branches if (b.from == bus_id || b.to == bus_id)]
branches(network::PowerFlowNetwork, bus_id1, bus_id2) = [b for b in network.branches if (b.from == bus_id1 && b.to == bus_id2) || (b.from == bus_id2 && b.to == bus_id1)]
nbus(network::PowerFlowNetwork) = length(network.buses)
ngen(network::PowerFlowNetwork) = network.ngen
nbranch(network::PowerFlowNetwork) = length(network.branches)
normid(network::PowerFlowNetwork, bus_id) = findfirst(id -> id == bus_id, network.buses_order)
trueid(network::PowerFlowNetwork, norm_id) = network.buses_order[norm_id]
function refbus(network::PowerFlowNetwork)
    refbuses = filter(b -> b.type == ref, collect(values(network.buses)))
    return refbuses[1]
end


function hasgen(network, bus_id)
    return bus_id in keys(network.generators)
end

function hasgencost(network)
    return any([!isempty(gen.active_cost_coeff) for gen in generators(network)])
end

function hasbranch_directed(network, from, to)
    return !isnothing(findfirst(b -> b.from == from && b.to == to, network.branches))
end

function hasbranch(network, b, a)
    return !isnothing(findifrst(b -> (b.from == b && b.to == a) || (b.to == b && b.from == a),
                                network.branches))
end
