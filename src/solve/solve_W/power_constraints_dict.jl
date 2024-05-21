function _expression_phi_real_L0(model, network, branch, W::DefaultDict)
    _nbus = nbus(network)
    b = normid(network, branch.from)
    a = normid(network, branch.to)
    _yff = yff(branch)
    _yft = yft(branch)
    _yffr, _yffc = real(_yff), imag(_yff)
    _yftr, _yftc = real(_yft), imag(_yft)
    @expression(model, _yffr * W["$(b), $(b)"] +
                       _yftr * W["$(b), $(a)"] +
                       _yftc * W["$(a), $(_nbus + b)"] -
                       _yftc * W["$(b), $(_nbus + a)"] +
                       _yffr * W["$(_nbus + b), $(_nbus + b)"] +
                       _yftr * W["$(_nbus + b), $(_nbus + a)"])
end


function _expression_phi_real_L1(model, network, branch, W::DefaultDict)
    _nbus = nbus(network)
    b = normid(network, branch.from)
    a = normid(network, branch.to)
    _ytt = ytt(branch)
    _ytf = ytf(branch)
    _yttr, _yttc = real(_ytt), imag(_ytt)
    _ytfr, _ytfc = real(_ytf), imag(_ytf)
    @expression(model, _yttr * W["$(b), $(b)"] +
                       _ytfr * W["$(b), $(a)"] +
                       _ytfc * W["$(a), $(_nbus + b)"] -
                       _ytfc * W["$(b), $(_nbus + a)"] +
                       _yttr * W["$(_nbus + b), $(_nbus + b)"] +
                       _ytfr * W["$(_nbus + b), $(_nbus + a)"])
end


function _expression_phi_imag_L0(model, network, branch, W::DefaultDict)
    _nbus = nbus(network)
    b = normid(network, branch.from)
    a = normid(network, branch.to)
    _yff = yff(branch)
    _yft = yft(branch)
    _yffr, _yffc = real(_yff), imag(_yff)
    _yftr, _yftc = real(_yft), imag(_yft)
    @expression(model, _yffc * W["$(b), $(b)"] +
                       _yftc * W["$(b), $(a)"] +
                       _yftr * W["$(b), $(_nbus + a)"] -
                       _yftr * W["$(a), $(_nbus + b)"] +
                       _yffc * W["$(_nbus + b), $(_nbus + b)"] +
                       _yftc * W["$(_nbus + b), $(_nbus + a)"])
end


function _expression_phi_imag_L1(model, network, branch, W::DefaultDict)
    _nbus = nbus(network)
    b = normid(network, branch.from)
    a = normid(network, branch.to)
    _ytt = ytt(branch)
    _ytf = ytf(branch)
    _yttr, _yttc = real(_ytt), imag(_ytt)
    _ytfr, _ytfc = real(_ytf), imag(_ytf)
    @expression(model, _yttc * W["$(b), $(b)"] +
                       _ytfc * W["$(b), $(a)"] +
                       _ytfr * W["$(b), $(_nbus + a)"] -
                       _ytfr * W["$(a), $(_nbus + b)"] +
                       _yttc * W["$(_nbus + b), $(_nbus + b)"] +
                       _ytfc * W["$(_nbus + b), $(_nbus + a)"])
end
