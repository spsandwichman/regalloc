package regalloc

import "core:fmt"
import "core:os"

NO_HINT :: max(uint)

available_registers     := [?]uint  {0,    1,    2,    3,    4,    5}
available_registers_str := [?]string{"ra", "rb", "rc", "rd", "re", "rf"}

// tries to assign a register to the start of a variable's lifetime
hint_reg_start :: proc(p: ^program, var, reg: uint) {
    // is it hinted at all?
    if p.variables[var].real == NO_HINT {
        p.variables[var].real = reg
        return
    }
    // is it hinted, but is the register the same as the new hint?
    if p.variables[var].real == reg do return

    // register is already hinted. 
    // we have to split the lifetime
    new := split_live_range(p, var, p.variables[var].live.start+1)
    p.variables[new].real = p.variables[var].real
    p.variables[var].real = reg
    calculate_liveness(p)
    return
}

// tries to assign a register to the end of a variable's lifetime
hint_reg_end :: proc(p: ^program, var, reg: uint) {
    // is it hinted at all?
    if p.variables[var].real == NO_HINT {
        p.variables[var].real = reg
        return
    }
    // is it hinted, but is the register the same as the new hint?
    if p.variables[var].real == reg do return 

    // register is already hinted. 
    // we have to split the lifetime
    new := split_live_range(p, var, p.variables[var].live.end-1)
    p.variables[new].real = reg
    calculate_liveness(p)
    return
}

clear_regalloc :: proc(p: ^program) {
    for &v in p.variables {
        v.real = NO_HINT
    }
}

out_of_registers :: proc() -> ! {
    fmt.println("OUT OF REGISTERS!")
    os.exit(1);
}