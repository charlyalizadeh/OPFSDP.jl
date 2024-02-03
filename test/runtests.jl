using OPFSDP
using Test

function check_bus(
		bus::OPFSDP.Bus,
		v::Complex, load::Complex, vmin::Float64, vmax::Float64,
		power::Complex, Pmin::Float64, Pmax::Float64, Qmin::Float64, Qmax::Float64,
		gen::Bool)
	@test bus.v == v
	@test bus.load == load
	@test bus.vmin == vmin
	@test bus.vmax == vmax
	@test bus.power == power
	@test bus.Pmin == Pmin
	@test bus.Pmax == Pmax
	@test bus.Qmin == Qmin
	@test bus.Qmax == Qmax
	@test bus.gen == gen
end

function check_bus(bus::OPFSDP.Bus, v::Complex, load::Complex, vmin::Float64, vmax::Float64)
	check_bus(bus,
			  v, load, vmin, vmax,
			  complex(0, 0), 0., 0., 0., 0., false)
end

@testset "OPFSDP.jl" begin
	network = read_matpower("data/case14.m")
    # Formated for easy maintenance
    #         BUS_ID             VOLTAGE                         DEMAND                             VMIN  VMAX  POWER GENERATION                      PMIN         PMAX         QMIN          QMAX GEN
	check_bus(network.buses[1],  complex(1.06, 0. / 100.),       complex(0. / 100., 0. / 100.),     0.94, 1.06, complex(232.4 / 100., -16.9 / 100.),  0. / 100.,   332.4 / 100., 0. / 100.,   10. / 100., true)
	check_bus(network.buses[2],  complex(1.045, -4.98 / 100.),   complex(21.7 / 100., 12.7 / 100.), 0.94, 1.06, complex(40. / 100., 42.4 / 100.),     0. / 100.,   140. / 100.,  -40. / 100., 50. / 100., true)
	check_bus(network.buses[3],  complex(1.01, -12.72 / 100.),   complex(94.2 / 100., 19 / 100.),   0.94, 1.06, complex(0. / 100., 23.4 / 100.),      0. / 100.,   100. / 100.,  0. / 100.,   40. / 100., true)
	check_bus(network.buses[4],  complex(1.019, -10.33 / 100.),  complex(47.8 / 100., -3.9 / 100.), 0.94, 1.06)
	check_bus(network.buses[5],  complex(1.02, -8.78 / 100.),    complex(7.6 / 100., 1.6 / 100.),   0.94, 1.06)
	check_bus(network.buses[6],  complex(1.07, -14.22 / 100.),   complex(11.2 / 100., 7.5 / 100.),  0.94, 1.06, complex(0. / 100., 12.2 / 100.),      0. / 100.,   100. / 100.,  -6. / 100.,  24. / 100., true)
	check_bus(network.buses[7],  complex(1.062, -13.37 / 100.),  complex(0 / 100., 0 / 100.),       0.94, 1.06)
	check_bus(network.buses[8],  complex(1.09, -13.36 / 100.),   complex(0 / 100., 0 / 100.),       0.94, 1.06, complex(0. / 100., 17.4 / 100.),      0. / 100.,   100. / 100.,  -6. / 100.,  24. / 100., true)
	check_bus(network.buses[9],  complex(1.056, -14.94 / 100.),  complex(29.5 / 100., 16.6 / 100.), 0.94, 1.06)
	check_bus(network.buses[10], complex(1.051, -15.1 / 100.),   complex(9 / 100., 5.8 / 100.),     0.94, 1.06)
	check_bus(network.buses[11], complex(1.057, -14.79 / 100.),  complex(3.5 / 100., 1.8 / 100.),   0.94, 1.06)
	check_bus(network.buses[12], complex(1.055, -15.07 / 100.),  complex(6.1 / 100., 1.6 / 100.),   0.94, 1.06)
	check_bus(network.buses[13], complex(1.05, -15.16 / 100.),   complex(13.5 / 100., 5.8 / 100.),  0.94, 1.06)
	check_bus(network.buses[14], complex(1.036, -16.04 / 100.),  complex(14.9 / 100., 5 / 100.),    0.94, 1.06)
end
