function dotJuMP(model, vectconst, vectvar)
    return @expression(model, sum(vectconst[i] * vectvar[i] for i in 1:length(vectconst)))
end


function trJuMP(model, matconst, matvar)
    return @expression(model, sum(dotJuMP(model, matconst[i, begin:end], matvar[begin:end, i]) for i in 1:size(matconst, 1)))
end


function mod2sumJuMP(model, var1, var2)
    return @expression(model, real(var1)^2 + 2 * real(var1) * real(var2) + real(var2)^2 +
                              imag(var1)^2 + 2 * imag(var1) * imag(var2) + imag(var2)^2)
end
