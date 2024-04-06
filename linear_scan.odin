package regalloc

least_reg_free :: proc(p: ^program, position: uint) -> uint {
    next_reg: for r in available_registers {
        
        for v in 0..<len(p.variables) {
            if !is_live_at(p, uint(v), position) do continue
            
            if (p.variables[v].real == r) {
                continue next_reg
            }

        }

        return r

    }

    out_of_registers()
}

linear_scan :: proc(p: ^program) {
    for &v in p.variables {
        if (v.real == NO_HINT) {
            v.real = least_reg_free(p, v.live.start)
        }
    }
}