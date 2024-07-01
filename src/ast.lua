--// Types //--

export type AstType = 
    --STATEMENTS
    "reg_def"       |
    "func_def"      |
    "loop_instr"    |
    "mov_instr"     |
    "lsjmp_instr"   |
    "grjmp_instr"   |
    "eqjmp_instr"   |
    "push_instr"    |
    "pop_instr"     |
    "syscall_instr" |
    "call_instr"    |
    "raw_instr"     |
    "ret_instr"     |
    "brk_instr"     |
    --EXPRESSIONS
    "register"      |
    "ident"         |
    "number"        |
    "string"        |
    "binary"        |
    --SYSTEM
    "compound"
    
export type AstNode = {
    kind: AstType,
    body: {AstNode},
    stringValue: string,
    numberValue: number,
}

--// Module //--

return {}