module OPFSDP

using JuMP
using Mosek
using MosekTools
using SparseArrays
using LinearAlgebra
using Logging



@enum CostType begin
    piecewise_linear = 1
    quadratic = 2
end

mutable struct Bus
	id::Int
	v::Complex
	load::Complex
	vmin::Float64
	vmax::Float64

    function Bus(id::Int=-1, v::Complex=complex(0., 0.), load::Complex=complex(0., 0.), vmin::Float64=0., vmax::Float64=0.)
		new(id, v, load, vmin, vmax)
    end
end

mutable struct Generator
	id::Int
    genid::Int
	power::Complex
	Pmin::Float64
	Pmax::Float64
	Qmin::Float64
	Qmax::Float64
    active_cost_coeff::Vector{Float64}
    reactive_cost_coeff::Vector{Float64}
    active_cost_type::Union{CostType,Nothing}
    reactive_cost_type::Union{CostType,Nothing}

	function Generator(id::Int, genid::Int,
                       power::Complex=complex(0., 0.),
                       Pmin::Float64=0., Pmax::Float64=0.,
                       Qmin::Float64=0., Qmax::Float64=0.,
					   active_cost_coeff::Vector{Float64}=Float64[], reactive_cost_coeff::Vector{Float64}=Float64[],
                       active_cost_type::Union{CostType,Nothing}=nothing, reactive_cost_type::Union{CostType,Nothing}=nothing)
		new(id, genid, power, Pmin, Pmax, Qmin, Qmax, active_cost_coeff, reactive_cost_coeff, active_cost_type, reactive_cost_type)
	end
end

mutable struct Branch
	src::Int
	dst::Int
	admittance::Complex
	susceptance::Float64
	tf_ratio::Float64
	tf_ps_angle::Float64
	rateA::Float64
	rateB::Float64
	rateC::Float64
end

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

function get_branches_in(network, bus_id)
	return [b for b in network.branches if b.dst == bus_id]
end

function get_branches_out(network, bus_id)
	return [b for b in network.branches if b.src == bus_id]
end

function generators(network::PowerFlowNetwork)
    return vcat([gen for gen in values(network.generators)]...)
end

include("io/read_matpower.jl")
include("utils/compute_current.jl")
include("utils/compute_power.jl")
include("utils/graphs.jl")
include("display/display_opf.jl")
include("decompose/cliques.jl")
include("decompose/cliquetree.jl")
include("decompose/chordal.jl")
include("decompose/extension/cholesky.jl")

include("solve/utils.jl")
include("solve/branch_flow_limit.jl")
include("solve/linking_constraint.jl")
include("solve/objective.jl")
include("solve/power_balance.jl")
include("solve/power_limit.jl")
include("solve/solve.jl")
include("solve/utils.jl")
include("solve/variables.jl")
include("solve/voltage_limit.jl")
include("solve/solve.jl")

export read_matpower
export compute_current_origin, compute_current_destination
export compute_powers, compute_power_src, compute_power_dst, str_power_src, str_power_dst
export get_branches_in, get_branches_out
export display_opf
export solve!

end
