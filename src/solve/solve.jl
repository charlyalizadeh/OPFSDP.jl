function computeY(network::PowerFlowNetwork)
    zero = 1e-10
    _nbus = nbus(network)
    YffR = zeros(_nbus, _nbus)
    YffC = zeros(_nbus, _nbus)
    YftR = zeros(_nbus, _nbus)
    YftC = zeros(_nbus, _nbus)
    YtfR = zeros(_nbus, _nbus)
    YtfC = zeros(_nbus, _nbus)
    YttR = zeros(_nbus, _nbus)
    YttC = zeros(_nbus, _nbus)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        r = branch.r
        x = branch.x
        bb = branch.b
        tau = branch.ratio
        sigma = (pi * branch.angle) / 180
        nu = sigma
        N = tau*exp(im*sigma)
        if abs(N) < zero
            tau = 1
        end
        YffR[b, a] = r / ((r^2 + x^2) * tau^2)
        YffC[b, a] = (bb * (r^2 + x^2) - 2 * x) / (2 * (r^2 + x^2) * tau^2)
        YftR[b, a] = -(r * cos(nu) + x * sin(nu)) / ((r^2 + x^2) * tau);
        YftC[b, a] = -(r * sin(nu) - x * cos(nu)) / ((r^2 + x^2) * tau);
        YtfR[b, a] = (x * sin(nu) - r * cos(nu)) / ((r^2 + x^2) * tau);
        YtfC[b, a] = (r * sin(nu) + x * cos(nu)) / ((r^2 + x^2) * tau);
        YttR[b, a] = r / (r^2 + x^2);
        YttC[b, a] = (bb * (r^2 + x^2) - 2 * x) / (2 * (r^2 + x^2));
    end
    return Dict("YffR" => YffR, "YffC" => YffC, "YftR" => YftR, "YftC" => YftC, "YtfR" => YtfR, "YtfC" => YtfC, "YttR" => YttR, "YttC" => YttC)
end

function computeYcomplex(network::PowerFlowNetwork)
    zero = 1e-10
    _nbus = nbus(network)
    Yff = zeros(Complex, _nbus, _nbus)
    Yft = zeros(Complex, _nbus, _nbus)
    Ytf = zeros(Complex, _nbus, _nbus)
    Ytt = zeros(Complex, _nbus, _nbus)
    for branch in branches(network)
        b = normid(network, branch.from)
        a = normid(network, branch.to)
        r = branch.r
        x = branch.x
        bb = branch.b
        tau = branch.ratio
        sigma = branch.angle
        N = tau*exp(im*sigma)
        if abs(N) < zero
            tau = 1
        end
        ys = 1 / (r + im * x)
        Yff[b, a] = (ys + im * bb / 2) / tau^2
        Yft[b, a] = - ys / (tau * exp(-im * sigma))
        Ytf[b, a] = - ys / (tau * exp(im * sigma))
        Ytt[b, a] = ys + im * bb / 2
    end
    return Dict("Yff" => Yff, "Yft" => Yft, "Ytf" => Ytf, "Ytt" => Ytt)
end

function computeYproducts(network, Y)
    _nbus = nbus(network)
    Yff2 = zeros(_nbus, _nbus)
    Yft2 = zeros(_nbus, _nbus)
    Ytf2 = zeros(_nbus, _nbus)
    Ytt2 = zeros(_nbus, _nbus)
    YffYftR = zeros(_nbus, _nbus)
    YffYftC = zeros(_nbus, _nbus)
    YtfYttR = zeros(_nbus, _nbus)
    YtfYttC = zeros(_nbus, _nbus)
    for branch in branches(network)
        b = normid(network, branch)
        a = normid(network, branch)
        Yff2 = Y["YffR"][b, a]^2 + Y["YffC"][b, a]^2;
        Yft2 = Y["YftR"][b, a]^2 + Y["YftC"][b, a]^2;
        Ytf2 = Y["YtfR"][b, a]^2 + Y["YtfC"][b, a]^2;
        Ytt2 = Y["YttR"][b, a]^2 + Y["YttC"][b, a]^2;
        YffYftR = Y["YffR"][b, a] * Y["YftR"][b, a] + Y["YffC"][b, a] * Y["YftC"][b, a];
        YffYftC = Y["YffR"][b, a] * Y["YftC"][b, a] - Y["YffC"][b, a] * Y["YftR"][b, a];
        YtfYttR = Y["YtfR"][b, a] * Y["YttR"][b, a] + Y["YtfC"][b, a] * Y["YttC"][b, a];
        YtfYttC = Y["YtfR"][b, a] * Y["YttC"][b, a] - Y["YtfC"][b, a] * Y["YttR"][b, a];
    end
    return Dict("Yff2" => Yff2, "Yft2" => Yft2, "Ytf2" => Ytf2, "Ytt2" => Ytt2, "YffYftR" => YffYftR, "YffYftC" => YffYftC, "YtfYttR" => YtfYttR, "YtfYttC" => YtfYttC)
end

function build_model(network::PowerFlowNetwork, cliques, cliquetree)
    model = Model(Mosek.Optimizer)
    Y = computeYcomplex(network)

    # Variables
    variables = _define_cliques!(model, network, cliques)
    merge!(variables, _define_generator_power_variables!(model, network))
    merge!(variables, _define_flow_variables!(model, network))
    X = _map_X!(model, network, cliques, variables)
    merge!(variables, _define_abs2_variables!(model, network, X))


    # Objective
    _define_objective_polynomial!(model, network, variables)

    # Constraints
    #_define_branch_current_flow_constraints!(model, network, variables, X, Y)
    _define_branch_power_flow_constraints!(model, network, variables, X, Y)
    _define_power_balance_constraints!(model, network, variables, X)
    #_define_voltage_angle_limit_constraints!(model, network, X)
    _define_voltage_limit_constraints!(model, network, variables, X)
    _define_linking_constraints!(model, variables, cliques, cliquetree)

    return model
end

function solve(network, cliques, cliquetree)
    build_time = @elapsed (model = build_model(network, cliques, cliquetree))
    println("Building time: $build_time (s)")
    optimize!(model)
    return model
end
