# OPFSDP

Code to solve SemiDefinite Relaxation of Optimal Power Flow network.
(!! Should not be used as a reliable solver !!)
The tests are not up to date.

## Objective

Here are the objectives values for the MATPOWER instances between 1000 and 10000 nodes (the instance in **bold** are the one not converging):

| Name             | Cholesky obj | Molzahn merge obj|
|------------------|--------------|------------------|
| case1354pegase   | 74054        | 74054            |
| case1888rte      | 57587        | 57587            |
| case1951rte      | 80708        | 80709            |
| case2383wp       | 6            | 3                |
| case2736sp       | 945969       | 945969           |
| case2737sop      | 691136       | 691136           |
| case2746wop      | 1023317      | 1023317          |
| case2746wp       | 1166430      | 1164538          |
| case2848rte      | 45274        | 45274            |
| case2868rte      | 78396        | 78396            |
| **case2869pegase*| 0            | 0                |
| case3012wp       | 4            | 2                |
| case3120sp       | 1336862      | 1336862          |
| case3375wp       | 10           | 6                |
| **case6468rte**  | -0           | 0                |
| **case6470rte**  | 0            | 0                |
| **case6495rte**  | 0            | -0               |
| **case6515rte**  | 0            | 0                |
| case9241pegase   | 336842       | 435123           |
| case_ACTIVSg10k  | 1752765      | 1753438          |
| case_ACTIVSg2000 | 962479       | 962479           |

## Example

### Solving an instance

#### SDP formatulation

```julia
path = "/path/to/network"
model = OPFSDP.solve(network)
termination_status = JuMP.termination_status(model)
objective = JuMP.objective_value(model)
solve_time = JuMP.solve_time(model)
println("[$(termination_status)] $(path) solved in $(solve_time) seconds (obj: $(objective))")
```

#### Decomposed SDP formulation

```julia
path = "/path/to/network"
network = OPFSDP.read_network(path)
cadj = OPFSDP.cholesky_extension(network)
cliques = OPFSDP.maximal_cliques(cadj)
cliquetree = OPFSDP.maximal_cliquetree(cliques)

model = OPFSDP.solve(network, cliques, cliquetree)

termination_status = JuMP.termination_status(model)
objective = JuMP.objective_value(model)
solve_time = JuMP.solve_time(model)
println("[$(termination_status)] $(path) solved in $(solve_time) seconds (obj: $(objective))")
```

### Write a decomposition to txt file

```julia
path = "/path/to/network"
OPFSDP.write_decomposition(path, OPFSDP.CholeskyExtension)
```
