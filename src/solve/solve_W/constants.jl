function base(network, id)
    eb = zeros(nbus(network))
    eb[normid(network, id)] = 1
    return eb
end

function extract_line(matrix, line)
    return [zeros(eltype(matrix), line - 1, size(matrix, 2));
            transpose(matrix[line, begin:end]);
            zeros(eltype(matrix), size(matrix, 1) - line, size(matrix, 2))]
end

function regular_plus_transpose(matrix, line)
    new_matrix = zeros(size(matrix))
    new_matrix[line, begin:end] = matrix[line, begin:end]
    new_matrix[begin:end, line] = matrix[line, begin:end]
    new_matrix[line, line] = 2 * matrix[line, line]
    return new_matrix
end
transpose_plus_regular(matrix, line) = regular_plus_tranpose(matrix, line)

function regular_minus_transpose(matrix, line)
    new_matrix = zeros(size(matrix))
    new_matrix[line, begin:end] = matrix[line, begin:end]
    new_matrix[begin:end, line] = -matrix[line, begin:end]
    new_matrix[line, line] = 0
    return new_matrix
end

function transpose_minus_regular(matrix, line)
    new_matrix = zeros(size(matrix))
    new_matrix[line, begin:end] = -matrix[line, begin:end]
    new_matrix[begin:end, line] = matrix[line, begin:end]
    new_matrix[line, line] = 0
    return new_matrix
end

function psi_real(network, bus, Y)
    nid = normid(network, bus.id)
    realY = real(Y)
    imagY = imag(Y)
    a = regular_plus_transpose(realY, nid)
    b = transpose_minus_regular(imagY, nid)
    c = regular_minus_transpose(imagY, nid)
    return 1/2*[a b;
                c a]
end

function psi_imag(network, bus, Y)
    nid = normid(network, bus.id)
    realY = real(Y)
    imagY = imag(Y)
    a = regular_plus_transpose(imagY, nid)
    b = regular_minus_transpose(realY, nid)
    c = transpose_minus_regular(realY, nid)
    return -1/2*[a b;
                 c a]
end

function phi_L0_real(network, branch)
    _nbus = nbus(network)
    phi = zeros(_nbus * 2, _nbus * 2)
    nidfrom = normid(network, branch.from)
    nidto = normid(network, branch.to)
    _yff = yff(branch)
    _yft = yft(branch)
    yffr = real(_yff); yffc = imag(_yff)
    yftr = real(_yft); yftc = imag(_yft)

    phi[nidfrom, nidfrom]   = yffr
    phi[nidfrom, nidto]     = yftr / 2
    phi[nidto,   nidfrom]   = yftr / 2

    #phi[nidfrom, _nbus + nidfrom]   = 0
    phi[nidfrom, _nbus + nidto]     = -yftc / 2
    phi[nidto,   _nbus + nidfrom]   = yftc / 2

    #phi[_nbus + nidfrom, nidfrom]    = 0
    phi[_nbus + nidfrom, nidto]      = yftc / 2
    phi[_nbus + nidto, nidfrom]      = -yftc / 2


    phi[_nbus + nidfrom, _nbus + nidfrom] = yffr
    phi[_nbus + nidfrom, _nbus + nidto] = yftr / 2
    phi[_nbus + nidto,   _nbus + nidfrom] = yftr / 2

    return phi
end


function phi_L0_imag(network, branch)
    _nbus = nbus(network)
    phi = zeros(_nbus * 2, _nbus * 2)
    nidfrom = normid(network, branch.from)
    nidto = normid(network, branch.to)
    _yff = yff(branch)
    _yft = yft(branch)
    yffr = real(_yff); yffc = imag(_yff)
    yftr = real(_yft); yftc = imag(_yft)

    phi[nidfrom, nidfrom]   = -yffc
    phi[nidfrom, nidto]     = -yftc / 2
    phi[nidto,   nidfrom]   = -yftc / 2

    #phi[nidfrom, _nbus + nidfrom]   = 0
    phi[nidfrom, _nbus + nidto]     = -yftr / 2
    phi[nidto,   _nbus + nidfrom]   = yftr / 2

    #phi[_nbus + nidfrom, nidfrom]    = 0
    phi[_nbus + nidfrom, nidto]      = yftr / 2
    phi[_nbus + nidto, nidfrom]      = -yftr / 2


    phi[_nbus + nidfrom, _nbus + nidfrom] = -yffc
    phi[_nbus + nidfrom, _nbus + nidto] = -yftc / 2
    phi[_nbus + nidto,   _nbus + nidfrom] = -yftc / 2

    return phi
end


function phi_L1_real(network, branch)
    _nbus = nbus(network)
    phi = zeros(_nbus * 2, _nbus * 2)
    nidfrom = normid(network, branch.from)
    nidto = normid(network, branch.to)
    _ytt = ytt(branch)
    _ytf = ytf(branch)
    yttr = real(_ytt); yttc = imag(_ytt)
    ytfr = real(_ytf); ytfc = imag(_ytf)

    phi[nidfrom, nidfrom]   = yttr
    phi[nidfrom, nidto]     = ytfr / 2
    phi[nidto,   nidfrom]   = ytfr / 2

    #phi[nidfrom, _nbus + nidfrom]   = 0
    phi[nidfrom, _nbus + nidto]     = -ytfc / 2
    phi[nidto,   _nbus + nidfrom]   = ytfc / 2

    #phi[_nbus + nidfrom, nidfrom]    = 0
    phi[_nbus + nidfrom, nidto]      = ytfc / 2
    phi[_nbus + nidto, nidfrom]      = -ytfc / 2


    phi[_nbus + nidfrom, _nbus + nidfrom] = yttr
    phi[_nbus + nidfrom, _nbus + nidto] = ytfr / 2
    phi[_nbus + nidto,   _nbus + nidfrom] = ytfr / 2

    return phi
end


function phi_L1_imag(network, branch)
    _nbus = nbus(network)
    phi = zeros(_nbus * 2, _nbus * 2)
    nidfrom = normid(network, branch.from)
    nidto = normid(network, branch.to)
    _ytt = ytt(branch)
    _ytf = ytf(branch)
    yttr = real(_ytt); yttc = imag(_ytt)
    ytfr = real(_ytf); ytfc = imag(_ytf)

    phi[nidfrom, nidfrom]   = -yttc
    phi[nidfrom, nidto]     = -ytfc / 2
    phi[nidto,   nidfrom]   = -ytfc / 2

    #phi[nidfrom, _nbus + nidfrom]   = 0
    phi[nidfrom, _nbus + nidto]     = -ytfr / 2
    phi[nidto,   _nbus + nidfrom]   = ytfr / 2

    #phi[_nbus + nidfrom, nidfrom]    = 0
    phi[_nbus + nidfrom, nidto]      = ytfr / 2
    phi[_nbus + nidto, nidfrom]      = -ytfr / 2


    phi[_nbus + nidfrom, _nbus + nidfrom] = -yttc
    phi[_nbus + nidfrom, _nbus + nidto] = -ytfc / 2
    phi[_nbus + nidto,   _nbus + nidfrom] = -ytfc / 2

    return phi
end


function theta_real(network, b, a)
    nb = normid(network, b)
    na = normid(network, a)
    _nbus = nbus(network)
    theta = zeros(_nbus * 2, _nbus * 2)
    value = nb == na ? 1 : 1/2
    theta[nb, na] = value
    theta[na, nb] = value
    theta[_nbus + nb, _nbus + na] = value
    theta[_nbus + na, _nbus + nb] = value
    return theta
end


function theta_imag(network, b, a)
    nb = normid(network, b)
    na = normid(network, a)
    _nbus = nbus(network)
    theta = zeros(_nbus * 2, _nbus * 2)
    (nb == na) && (return theta)
    theta[nb, _nbus + na] = -1/2
    theta[na, _nbus + nb] = 1/2
    theta[_nbus + na,  nb] = -1/2
    theta[_nbus + nb,  na] = 1/2
    return theta
end
