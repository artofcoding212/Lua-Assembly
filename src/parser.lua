--// Variables //--

local Ast = require(script.Parent.Ast)
local Lexer = require(script.Parent.Lexer)

--// Types //--

export type Parser = {
    __index: Parser,
    lexer: Lexer.Lexer,
    token: Lexer.Token,
    
    new: (lexer: Lexer.Lexer)->Parser,
    Parse: (self: Parser)->Ast.AstNode,
    ParseStmt: (self: Parser)->Ast.AstNode,
    ParseExpr: (self: Parser)->Ast.AstNode,
    
    ParseTerm: (self: Parser)->Ast.AstNode,
    ParseFactor: (self: Parser)->Ast.AstNode,
    ParsePrimary: (self: Parser)->Ast.AstNode,
    ParseRegister: (self: Parser)->Ast.AstNode,
    ParseNumber: (self: Parser)->Ast.AstNode,
    ParseString: (self: Parser)->Ast.AstNode,
    ParseIdent: (self: Parser)->Ast.AstNode,
    
    Advance: (self: Parser, kind: Lexer.TokenType)->(),
}

--// Module //--

local parser: Parser = {}
parser.__index = parser

function parser.new(lexer: Lexer.Lexer): Parser
    local self: Parser = setmetatable({}, parser)
    self.lexer = lexer
    self.token = lexer:NextToken()
    
    return self
end

function parser:Advance(kind: Lexer.TokenType)
   if self.token.kind ~= kind then
        error(`[Parser]-> Expected a token of type {kind}, instead got a token of type {self.token.kind}.`)
   end
   
   self.token = self.lexer:NextToken()
end

function parser:Parse(): Ast.AstNode
    local compound: Ast.AstNode = {kind="compound", body={}}::Ast.AstNode
    
    while self.token.kind ~= "eof" do
        table.insert(compound.body, self:ParseStmt())
    end
    
    return compound
end

function parser:ParseStmt(): Ast.AstNode
    local keywords: {[string]: ()->Ast.AstNode} = {
        ["mkreg"] = function()
            local node: Ast.AstNode = {kind="reg_def", body={}}::Ast.AstNode
            
            while self.token.kind == "identifier" do
                table.insert(node.body, {kind="ident", stringValue=self.token.value}::Ast.AstNode)
                self:Advance("identifier")
                
                if self.token.kind ~= "comma"::Lexer.TokenType then
                    break
                end
                
                self:Advance("comma")
            end
            
            return node
        end,
        ["func"] = function()
            local node: Ast.AstNode = {kind="func_def", stringValue=self.token.value, body={}}::Ast.AstNode
            self:Advance("identifier")
            self:Advance("lbrace")
            
            while self.token.kind ~= "eof" and self.token.kind ~= "rbrace" do
                table.insert(node.body, self:ParseStmt())
            end
            
            self:Advance("rbrace")
            return node
        end,
        ["loop"] = function()
            local node: Ast.AstNode = {kind="loop_instr", body={}}::Ast.AstNode
            self:Advance("lbrace")

            while self.token.kind ~= "eof" and self.token.kind ~= "rbrace" do
                table.insert(node.body, self:ParseStmt())
            end

            self:Advance("rbrace")
            return node
        end,
        ["mov"] = function()
            local node: Ast.AstNode = {kind="mov_instr", body={[1]=self:ParseRegister(), [2]=nil}}::Ast.AstNode
            self:Advance("comma")
            node.body[2] = self:ParseExpr()
            
            return node
        end,
        ["lsjmp"] = function()
            local node: Ast.AstNode = {kind="lsjmp_instr", body={[1]=self:ParseExpr(), [2]=nil, [3]={}}}::Ast.AstNode
            self:Advance("comma")
            node.body[2] = self:ParseExpr()
            
            self:Advance("lbrace")

            while self.token.kind ~= "eof" and self.token.kind ~= "rbrace" do
                table.insert(node.body[3], self:ParseStmt())
            end

            self:Advance("rbrace")
            return node
        end,
        ["grjmp"] = function()
            local node: Ast.AstNode = {kind="grjmp_instr", body={[1]=self:ParseExpr(), [2]=nil, [3]={}}}::Ast.AstNode
            self:Advance("comma")
            node.body[2] = self:ParseExpr()

            self:Advance("lbrace")

            while self.token.kind ~= "eof" and self.token.kind ~= "rbrace" do
                table.insert(node.body[3], self:ParseStmt())
            end

            self:Advance("rbrace")
            return node
        end,
        ["eqjmp"] = function()
            local node: Ast.AstNode = {kind="eqjmp_instr", body={[1]=self:ParseExpr(), [2]=nil, [3]={}}}::Ast.AstNode
            self:Advance("comma")
            node.body[2] = self:ParseExpr()

            self:Advance("lbrace")

            while self.token.kind ~= "eof" and self.token.kind ~= "rbrace" do
                table.insert(node.body[3], self:ParseStmt())
            end

            self:Advance("rbrace")
            return node
        end,
        ["push"] = function()
            return {kind="push_instr", body={[1]=self:ParseExpr()}}::Ast.AstNode
        end,
        ["pop"] = function()
            return {kind="pop_instr", body={[1]=self:ParseRegister()}}::Ast.AstNode
        end,
        ["syscall"] = function()
            return {kind="syscall_instr", body={[1]=self:ParseIdent()}}::Ast.AstNode
        end,
        ["call"] = function()
            return {kind="call_instr", body={[1]=self:ParseIdent()}}::Ast.AstNode
        end,
        ["raw"] = function()
            return {kind="raw_instr", body={[1]=self:ParseString()}}::Ast.AstNode
        end,
        ["ret"] = function()
            return {kind="ret_instr"}::Ast.AstNode
        end,
        ["brk"] = function()
            return {kind="brk_instr"}::Ast.AstNode
        end,
    }
    
    if self.token.kind == "identifier" and keywords[self.token.value] then
        local keyword = self.token.value
        self:Advance("identifier")
        local statement = keywords[keyword]()
        self:Advance("semicolon")
        return statement
    end
    
    local expression = self:ParseExpr()
    self:Advance("semicolon")
    return expression
end

function parser:ParseExpr()
    return self:ParseTerm()
end

function parser:ParseTerm()
    local left: Ast.AstNode = self:ParseFactor()
    
    while self.token.kind == "plus" or self.token.kind == "minus" do
        left = {kind="binary", body={[1]=left, [2]=nil}, stringValue=self.token.value}::Ast.AstNode
        self:Advance(self.token.kind)
        left.body[2] = self:ParseFactor()
    end
    
    return left
end

function parser:ParseFactor()
    local left: Ast.AstNode = self:ParsePrimary()
    
    while self.token.kind == "slash" or self.token.kind == "star" do
        left = {kind="binary", body={[1]=left, [2]=nil}, stringValue=self.token.value}::Ast.AstNode
        self:Advance(self.token.kind)
        left.body[2] = self:ParsePrimary()
    end
    
    return left
end

function parser:ParsePrimary()
    local expressions: {[Lexer.TokenType]: ()->Ast.AstNode} = {
        ["dollar"] = function() return self:ParseNumber() end,
        ["percent"] = function() return self:ParseRegister() end,
        ["string"] = function() return self:ParseString() end,
        ["lparen"] = function()
            self:Advance("lparen")
            local expression: Ast.AstNode = self:ParseExpr()
            self:Advance("rparen")
            return expression
        end,
    }
    
    if expressions[self.token.kind] then
        return expressions[self.token.kind]()
    end
    
    error(`[Parser]-> The token '{self.token.kind}' was not parsed.`)    
end

function parser:ParseNumber()
    self:Advance("dollar")
    local node: Ast.AstNode = {kind="number", numberValue=tonumber(self.token.value)}::Ast.AstNode
    self:Advance("number")
    
    return node
end

function parser:ParseRegister()
    self:Advance("percent")
    local node: Ast.AstNode = {kind="register", stringValue=self.token.value}::Ast.AstNode
    self:Advance("identifier")

    return node
end

function parser:ParseString()
    local node: Ast.AstNode = {kind="string", stringValue=self.token.value}::Ast.AstNode
    self:Advance("string")
    
    return node
end

function parser:ParseIdent()
    local node: Ast.AstNode = {kind="ident", stringValue=self.token.value}::Ast.AstNode
    self:Advance("identifier")

    return node
end

return parser