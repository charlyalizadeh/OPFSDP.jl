function compute_current_src(v_src::Complex, v_dst::Complex,
        admittance::Complex, susceptance::Float64,
        tf_ratio::Float64, tf_ps_angle::Float64)
    return ((conj(admittance) + susceptance * im) / tf_ratio^2) * v_src - conj(admittance) * (exp(-tf_ps_angle * im) / tf_ratio) * v_dst
end

function compute_current_dst(v_src::Complex, v_dst::Complex,
                             admittance::Complex, susceptance::Float64,
                             tf_ratio::Float64, tf_ps_angle::Float64)
    return -conj(admittance) * (exp(tf_ps_angle * im) / tf_ratio) * v_src + (conj(admittance) + susceptance * im) * v_dst
end

function compute_current(bus_dict, values, baseMVA)
    v_src = bus_dict[values[1]].v
    v_dst = bus_dict[values[2]].v
    admittance = 1 / complex(values[3], values[4])
    susceptance = values[5]
    tf_ratio = values[9] == 0 ? 1.0 : values[9]
    tf_ps_angle = values[10] / baseMVA
    return [compute_current_src(v_src, v_dst, admittance, susceptance, tf_ratio, tf_ps_angle),
            compute_current_dst(v_src, v_dst, admittance, susceptance, tf_ratio, tf_ps_angle)]
end
