# source: https://github.com/lanl-ansi/PowerModels.jl/blob/master/src/form/wrm.jl#L328
function cholesky_extension(network)
	adj = adjacency_matrix(network)
    nb = size(adj, 1)
    diag_el = sum(adj, dims=1)[:]
    W = Hermitian(-adj + spdiagm(0 => diag_el .+ 1))

    F = cholesky(W)
    L = sparse(F.L)
    q = invperm(F.p)

    Rchol = L - spdiagm(0 => diag(L))
    f_idx, t_idx, V = findnz(Rchol)
    cadj = sparse([f_idx;t_idx], [t_idx;f_idx], ones(2*length(f_idx)), nb, nb)
    cadj = cadj[q, q] # revert to original bus ordering (invert cholfact permutation)
    return cadj
end
