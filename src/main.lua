--// Variables //--

local Lexer = require(script.Lexer)
local Parser = require(script.Parser)
local Ast = require(script.Ast)
local Transpiler = require(script.Transpiler)

--// Types //--

type Main = {
    Transpile: (src: string)->string,
}

--// Module //--

local luaAsm: Main = {}

function luaAsm.Transpile(src: string): string
    local lexer: Lexer.Lexer = Lexer.new(src)
    local parser: Parser.Parser = Parser.new(lexer)
    local transpiler: Transpiler.Transpiler = Transpiler.new(parser)
    
    return transpiler:Transpile()
end

return luaAsm