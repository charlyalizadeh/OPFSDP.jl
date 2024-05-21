function dotJuMP(model, vectconst, vectvar)
    return @expression(model, sum(vectconst[i] * vectvar[i] for i in 1:length(vectconst)))
end


function trJuMP(model, matconst, matvar::LinearAlgebra.Symmetric)
    return @expression(model, sum(dotJuMP(model, matconst[i, begin:end], matvar[begin:end, i]) for i in 1:size(matconst, 1)))
end


function trJuMP(model, matconst, matvar::DefaultDict)
    return @expression(model, sum(dotJuMP(model, matconst[i, begin:end], [matvar["$j, $i"] for j in 1:size(matconst, 1)]) for i in 1:size(matconst, 1)))
end
