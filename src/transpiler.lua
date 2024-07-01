--// Variables //--

local Parser = require(script.Parent.Parser)
local Ast = require(script.Parent.Ast)

--// Types //--

export type TranspilerContext = {
    indentation: number,
    main: boolean,
}

export type Transpiler = {
    __index: Transpiler,
    parser: Parser.Parser,
    nodes: {Ast.AstNode},
    position: number,
    node: Ast.AstNode,
    result: string,
    
    new: (parser: Parser.Parser)->Transpiler,
    Transpile: (self: Transpiler)->string,
    TranspileNode: (self: Transpiler, node: Ast.AstNode, context: TranspilerContext)->string,
    Advance: (self: Transpiler)->(),
}

--// Module //--

local transpiler: Transpiler = {}
transpiler.__index = transpiler

function transpiler.new(parser: Parser.Parser): Transpiler
    local self: Transpiler = setmetatable({}, transpiler)
    self.parser = parser
    self.result = ""
    self.position = 1
    self.nodes = {}
    
    return self
end

function transpiler:Transpile(): string
    self.nodes = self.parser:Parse().body
    self.result = "local Registers: {[string]: any} = {"
    
    if self.nodes[1].kind == "reg_def" then
        local initalRegisters: Ast.AstNode = self.nodes[1]
        self:Advance()
        self.result = self.result.."\n"
        
        for index, register in initalRegisters.body do
            self.result = self.result..`\t["{register.stringValue}"] = 0,\n`
        end
    end
    
    self.result = self.result..[[}
local Stack: {any} = {}

local function syscall(call: string)
    --TODO - More system calls.
    local calls: {[string]: ()->()} = {
        ["print"] = function()
            print(Stack[#Stack])
        end,
        ["warn"] = function()
            warn(Stack[#Stack])
        end,
        ["error"] = function()
            error(Stack[#Stack])
        end,
    }
    
    if calls[call] then
        calls[call]()
    else
        error(`[TranspiledLuaAsm]-> The system call '{call}'' does not exist.`)
    end
end
]]
    
    while self.position <= #self.nodes do
        self.result = self.result..self:TranspileNode(self.node, {indentation=0, main=false})
    end
    
    self.result = self.result..[[

local exitCode: number = main()

if exitCode ~= 0 then
    error(`[TranspiledLuaAsm]-> Exited with exit code '{exitCode}'.`)
end
]]
    
    return self.result
end

function transpiler:TranspileNode(node: Ast.AstNode, context: TranspilerContext): string
    local nodes: {[Ast.AstType]: ()->string} = {
        ["reg_def"] = function()
            local result: string = ""
            
            for _, register in node.body do
                result = result..`Registers[{register.stringValue}] = 0\n`
            end
            
            return result
        end,
        ["func_def"] = function()
            local result: string = `local function {node.stringValue}(){node.stringValue == "main" and ": number" or ""}`
            
            if #node.body <= 0 then
                return result.." return end\n"
            end
            
            result = result.."\n"
            
            for _, child in node.body do
                result = result..self:TranspileNode(child, {indentation=context.indentation+1, main=node.stringValue == "main"})
            end
            
            return result.."end\n"
        end,
        ["loop_instr"] = function()
            local result: string = "while true do"
            
            if #node.body <= 0 then
                return result.." end\n"
            end
            
            result = result.."\n"
            
            for _, child in node.body do
                result = result..self:TranspileNode(child, {indentation=context.indentation+1, main=context.main})
            end
            
            return result.."end\n"
        end,
        ["mov_instr"] = function()
            return `Registers["{node.body[1].stringValue}"] = {self:TranspileNode(node.body[2], {indentation=0, main=context.main})}\n`
        end,
        ["lsjmp_instr"] = function()
            local result: string = `if {self:TranspileNode(node.body[1], {indentation=0, main=context.main})} < {self:TranspileNode(node.body[2], {indentation=0, main=context.main})} then`
            
            if #(node.body[3]::{Ast.AstNode}) <= 0 then
                return result.." end\n"
            end
            
            result = result.."\n"
            
            for _, child in node.body[3]::{Ast.AstNode} do
                result = result..self:TranspileNode(child, {indentation=context.indentation+1, main=context.main})
            end
            
            return result.."end\n"
        end,
        ["grjmp_instr"] = function()
            local result: string = `if {self:TranspileNode(node.body[1], {indentation=0, main=context.main})} > {self:TranspileNode(node.body[2], {indentation=0, main=context.main})} then`

            if #(node.body[3]::{Ast.AstNode}) <= 0 then
                return result.." end\n"
            end

            result = result.."\n"

            for _, child in node.body[3]::{Ast.AstNode} do
                result = result..self:TranspileNode(child, {indentation=context.indentation+1, main=context.main})
            end

            return result.."end\n"
        end,
        ["eqjmp_instr"] = function()
            local result: string = `if {self:TranspileNode(node.body[1], {indentation=0, main=context.main})} == {self:TranspileNode(node.body[2], {indentation=0, main=context.main})} then`

            if #(node.body[3]::{Ast.AstNode}) <= 0 then
                return result.." end\n"
            end

            result = result.."\n"

            for _, child in node.body[3]::{Ast.AstNode} do
                result = result..self:TranspileNode(child, {indentation=context.indentation+1, main=context.main})
            end

            return result.."end\n"
        end,
        ["push_instr"] = function()
            return `table.insert(Stack, {self:TranspileNode(node.body[1], {indentation=0, main=context.main})})\n`
        end,
        ["pop_instr"] = function()
            return `Registers["{node.body[1].stringValue}"] = table.remove(Stack)\n`
        end,
        ["syscall_instr"] = function()
            return `syscall("{node.body[1].stringValue}")\n`
        end,
        ["call_instr"] = function()
            return `{node.body[1].stringValue}()\n`
        end,
        ["raw_instr"] = function()
            local indentation = context.indentation <= 0 and "" or string.rep("\t", context.indentation)
            return `---RAW LUAU CODE---\n{indentation}{node.body[1].stringValue}\n{indentation}-------------------\n`
        end,
        ["ret_instr"] = function()
            return `return{context.main and " Stack[#Stack]" or ""}\n`
        end,
        ["brk_instr"] = function()
            return "break\n"
        end,
        ["register"] = function()
            return `Registers["{node.stringValue}"]`
        end,
        ["ident"] = function()
            return node.stringValue
        end,
        ["number"] = function()
            return tostring(node.numberValue)
        end,
        ["string"] = function()
            return `"{node.stringValue}"`
        end,
        ["binary"] = function()
            return `{self:TranspileNode(node.body[1], {indentation=0, main=context.main})} {node.stringValue} {self:TranspileNode(node.body[2], {indentation=0, main=context.main})}`
        end,
    }

    if nodes[node.kind] then
        self:Advance()
        return (context.indentation <= 0 and "" or string.rep("\t", context.indentation))..nodes[node.kind]()
    end
    
    error(`[Transpiler]-> The AST node '{node.kind}' is not recognized.`)
end

function transpiler:Advance()
    if self.position <= #self.nodes then
        self.position += 1
        self.node = self.nodes[self.position]
    end
end

return transpiler