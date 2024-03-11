power_balance_real = "Re(a) Im(v)^2 + Re(a) Re(v)^2 + Re(b) Im(v) Im(w) - Im(b) Im(v) Re(w) + Im(b) Im(w) Re(v) + Re(b) Re(v) Re(w)"
power_balance_imag = "(Im(a) Re(v)^2 + Im(a) Im(v)^2 + Re(b) Im(v) Re(w) - Re(b) Im(w) Re(v) + Im(b) Re(v) Re(w) + Im(b) Im(v) Im(w))"
branch_limit = "2 Re(a) Re(b) Im(v) Im(w) + 2 Re(a) Im(b) Im(v) Re(w) - 2 Im(a) Re(b) Im(v) Re(w) - 2 Re(a) Im(b) Im(w) Re(v) + 2 Im(a) Re(b) Im(w) Re(v) + 2 Im(a) Im(b) Re(v) Re(w) + 2 Im(a) Im(b) Im(v) Im(w) + 2 Re(a) Re(b) Re(v) Re(w) + Re(a)^2 Im(v)^2 + Im(a)^2 Re(v)^2 + Im(a)^2 Im(v)^2 + Re(a)^2 Re(v)^2 + Re(b)^2 Im(w)^2 + Im(b)^2 Re(w)^2 + Im(b)^2 Im(w)^2 + Re(b)^2 Re(w)^2"





def wolframe_to_jump(exp, v, w, a, b):
    replace = [
        ("Re(v)^2","Re(v) Re(v)"),
        ("Im(v)^2","Im(v) Im(v)"),
        ("Re(w)^2","Re(w) Re(w)"),
        ("Im(w)^2","Im(w) Im(w)"),
        (") R", ")*R"),
        (") I", ")*I"),
        ("2 I", "2*I"),
        ("2 R", "2*R"),
    ]
    for key, val in replace:
        exp = exp.replace(key, val)

    keys = ["Re(v)", "Im(v)", "Re(w)", "Im(w)"]
    vvm_keys = []
    for k1 in keys:
        for k2 in keys:
            vvm_keys.append(f"{k1}*{k2}")

    for key in vvm_keys:
        exp = exp.replace(key, f"vvm[\"{key}\"]")

    replace = [
        ("Im", "imag"),
        ("Re", "real"),
        ("(v)", f"({v})"),
        ("(w)", f"({w})"),
        ("(a)", f"({a})"),
        ("(b)", f"({b})")
    ]
    for key, val in replace:
        exp = exp.replace(key, val)
    return exp

branch_power_out_real = wolframe_to_jump(
    exp = power_balance_real,
    v = "v$(bus.id)",
    w = "v$(branch.dst)",
    a = "_branch_compute_power_origin_1(branch)",
    b = "_branch_compute_power_origin_2(branch)"
)

branch_power_out_imag = wolframe_to_jump(
    exp = power_balance_imag,
    v = "v$(bus.id)",
    w = "v$(branch.dst)",
    a = "_branch_compute_power_origin_1(branch)",
    b = "_branch_compute_power_origin_2(branch)"
)

branch_power_in_real = wolframe_to_jump(
    exp = power_balance_real,
    v = "v$(bus.id)",
    w = "v$(branch.src)",
    a = "_branch_compute_power_destination_2(branch)",
    b = "_branch_compute_power_destination_1(branch)"
)

branch_power_in_imag = wolframe_to_jump(
    exp = power_balance_imag,
    v = "v$(bus.id)",
    w = "v$(branch.src)",
    a = "_branch_compute_power_destination_2(branch)",
    b = "_branch_compute_power_destination_1(branch)"
)

current_limit_origin = wolframe_to_jump(
    exp = branch_limit,
    v = "v$(branch.src)",
    w = "v$(branch.dst)",
    a = "current[1]",
    b = "current[2]"
)

current_limit_destination = wolframe_to_jump(
    exp = branch_limit,
    v = "v$(branch.src)",
    w = "v$(branch.dst)",
    a = "current[1]",
    b = "current[2]"
)

print(current_limit_origin)

#2*real(current[1])*real(current[2])*vvm["imag(v$(branch.src))*imag(v$(branch.dst))"] +
#2*real(current[1])*imag(current[2])*vvm["imag(v$(branch.src))*real(v$(branch.dst))"] -
#2*imag(current[1])*real(current[2])*vvm["imag(v$(branch.src))*real(v$(branch.dst))"] -
#2*real(current[1])*imag(current[2])*vvm["imag(v$(branch.dst))*real(v$(branch.src))"] +
#2*imag(current[1])*real(current[2])*vvm["imag(v$(branch.dst))*real(v$(branch.src))"] +
#2*imag(current[1])*imag(current[2])*vvm["real(v$(branch.src))*real(v$(branch.dst))"] +
#2*imag(current[1])*imag(current[2])*vvm["imag(v$(branch.src))*imag(v$(branch.dst))"] +
#2*real(current[1])*real(current[2])*vvm["real(v$(branch.src))*real(v$(branch.dst))"] +
#real(current[1])^2*vvm["imag(v$(branch.src))*imag(v$(branch.src))"] +
#imag(current[1])^2*vvm["real(v$(branch.src))*real(v$(branch.src))"] +
#imag(current[1])^2*vvm["imag(v$(branch.src))*imag(v$(branch.src))"] +
#real(current[1])^2*vvm["real(v$(branch.src))*real(v$(branch.src))"] +
#real(current[2])^2*vvm["imag(v$(branch.dst))*imag(v$(branch.dst))"] +
#imag(current[2])^2*vvm["real(v$(branch.dst))*real(v$(branch.dst))"] +
#imag(current[2])^2*vvm["imag(v$(branch.dst))*imag(v$(branch.dst))"] +
#real(current[2])^2*vvm["real(v$(branch.dst))*real(v$(branch.dst))"]
