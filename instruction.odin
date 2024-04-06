package regalloc

import "core:fmt"

// everything assumes well-formed programs.
// this means variables are only assigned once, and they are created before they are used.

main :: proc() {
    p := program{}

    v1 := add_variable(&p)
    v2 := add_variable(&p)
    v3 := add_variable(&p)
    v4 := add_variable(&p)

    // v1 = 1
    i1 := add_instruction(&p)
    add_out(&p, i1, v1)

    // v2 = 1
    i2 := add_instruction(&p)
    add_out(&p, i2, v2)

    // v3 = v1 + v2
    i3 := add_instruction(&p)
    add_in(&p, i3, v1)
    add_in(&p, i3, v2)
    add_out(&p, i3, v3)

    // v4 = v1 * v3
    i4 := add_instruction(&p)
    add_in(&p, i4, v1)
    add_in(&p, i4, v3)
    add_out(&p, i4, v4)

    // return v4
    i5 := add_instruction(&p)
    add_in(&p, i5, v4)


    calculate_liveness(&p)
    print_program(&p)

    hint_reg_end(&p, v1, 4)
    hint_reg_start(&p, v1, 5)
    linear_scan(&p)
    print_program(&p)
}

live_range :: struct {
    start, end: uint
}

variable :: struct {
    real    : uint, // real register number

    live: live_range,
}

instr :: struct {
    ins, outs: [dynamic]uint
}

program :: struct {
    instrs    : [dynamic]instr,
    variables : [dynamic]variable,
}

does_use :: proc(p: ^program, inst, var: uint) -> bool {
    for u in p.instrs[inst].ins {
        if u == var do return true
    }

    for u in p.instrs[inst].outs {
        if u == var do return true
    }

    return false
}

calculate_liveness :: proc(p: ^program) {
    for v in 0..<uint(len(p.variables)) {
        
        // get start
        for i in 0..<uint(len(p.instrs)) {
            if does_use(p, i, v) {
                p.variables[v].live.start = i
                break;
            }
        }

        // get end
        for i := len(p.instrs)-1; i >= 0; i -= 1 {
            if does_use(p, uint(i), v) {
                p.variables[v].live.end = uint(i)
                break;
            }
        }
    }
}

split_live_range :: proc(p: ^program, var, position: uint) -> uint {
    if !is_live_at(p, var, position) do return max(uint)

    new := add_variable(p)

    inject_at(&p.instrs, int(position), instr{})
    append(&p.instrs[position].ins, var)
    append(&p.instrs[position].outs, new)
    
    for i in position+1..<uint(len(p.instrs)) {
        for &input in p.instrs[i].ins {
            if (input == var) {
                input = new;
            }
        }
        for &output in p.instrs[i].outs {
            if (output == var) {
                output = new;
            }
        }
    }
    return new
}

is_live_at :: #force_inline proc(p: ^program, var, position: uint) -> bool {
    return (
        p.variables[var].live.start <= position && 
        p.variables[var].live.end  > position)
}

add_variable :: proc(p: ^program) -> uint {
    v := variable{real = NO_HINT, live = {max(uint), max(uint)}}
    append(&p.variables, v)
    return len(p.variables) - 1
}

add_instruction :: proc(p: ^program) -> uint {
    v := instr{}
    v.ins  = make([dynamic]uint)
    v.outs = make([dynamic]uint)
    append(&p.instrs, v)
    return len(p.instrs) - 1
}

add_in :: proc(p: ^program, inst, var: uint) {
    append(&p.instrs[inst].ins, var)
}

add_out :: proc(p: ^program, inst, var: uint) {
    append(&p.instrs[inst].outs, var)
}

print_program :: proc(p: ^program) {

    fmt.print("\n")

    for v in 0..<cast(uint) len(p.variables) {
        fmt.printf("v%d  ", v)        
    }
    fmt.print("\n")

    for v in 0..<cast(uint) len(p.variables) {
        if p.variables[v].real != max(uint) {
            fmt.printf("%s  ", available_registers_str[p.variables[v].real])       
        } else {
            fmt.printf("    ")
        }
    
    }
    fmt.print("\n")


    for i in 0..<cast(uint) len(p.instrs) {

        for v in 0..<cast(uint) len(p.variables) {
            if is_live_at(p, v, i) {
                fmt.print("|   ")
            } else {
                if p.variables[v].live.end == i {
                    fmt.print("o   ")
                } else {
                    fmt.print("    ")
                }
            }
        }

        fmt.printf("    %v\t<- %v\t", p.instrs[i].outs, p.instrs[i].ins)

        fmt.print("\n")
    }
}