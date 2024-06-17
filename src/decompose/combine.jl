function combine(adj1::SparseMatrixCSC, adj2::SparseMatrixCSC)
    return (adj1 .== adj2)
end
