--// Types //--

export type TokenType = 
    --LITERALS
    "number"     |
    "identifier" |
    "string"     |
    --GROUPINGS
    "lparen"     |
    "rparen"     |
    "lbrace"     |
    "rbrace"     |
    "lbracket"   |
    "rbracket"   |
    --OPERATORS
    "plus"       |
    "minus"      |
    "star"       |
    "slash"      |
    "percent"    |
    "comma"      |
    "semicolon"  |
    "dollar"     |
    --SYSTEM
    "eof"

export type Token = {
    kind: TokenType,
    value: string,
}

export type Lexer = {
    __index: Lexer,
    src: {string},
    srcSize: number,
    position: number,
    current: string,
    
    new: (src: string)->Lexer,
    Advance: (self: Lexer)->(),
    NextToken: (self: Lexer)->Token,
}

--// Module //--

local lexer: Lexer = {}
lexer.__index = lexer

function lexer.new(src: string): Lexer
    local self: Lexer = setmetatable({}, lexer)
    self.src = src:split("")
    self.srcSize = #self.src
    self.position = 1
    self.current = self.src[self.position]
    
    return self
end

function lexer:Advance()
    if self.position <= self.srcSize then
        self.position += 1
        self.current = self.src[self.position]
    end
end

function lexer:NextToken(): Token    
    if self.current and (self.current == "#" or self.current == "\n" or self.current == "\r" or self.current == "\t" or self.current == " ") then
        local comment: boolean = self.current == "#"
        
        if comment then
            self:Advance()
        end
        
        while self.current and (self.current == "\n" or self.current == "\r" or self.current == "\t" or self.current == " " or self.current == "#" or comment) do
            if self.current == "\n" then comment = false end
            if self.current == "#" then comment = true end
            self:Advance()
        end
    end
    
    if tonumber(self.current) ~= nil or (self.current == "-" and tonumber(self.src[self.position + 1]) ~= nil) then
        local value: string = ""
        
        if self.current == "-" then
            value = value..self.current
            self:Advance()
        end
        
        while tonumber(self.current) ~= nil do
            value = value..self.current
            self:Advance()
        end
        
        if self.current == "." then
            value = value..self.current
            self:Advance()
            
            while tonumber(self.current) ~= nil do
                value = value..self.current
                self:Advance()
            end
        end
        
        return {kind="number", value=value}::Token
    end
    
    if self.current and self.current:upper() ~= self.current:lower() then
        local value: string = ""
        
        while self.current:upper() ~= self.current:lower() or tonumber(self.current) ~= nil or self.current == "_" do
            value = value..self.current
            self:Advance()
        end
        
        return {kind="identifier", value=value}::Token
    end
    
    if self.current and self.current == "\"" then
        local value: string = ""
        local ignoreNext: boolean = false
        self:Advance()
        
        while self.position <= self.srcSize and (self.current ~= "\"" or ignoreNext) do
            if self.current == "\\" then
                ignoreNext = true
                self:Advance()
                continue
            end
            
            value = value..self.current
            ignoreNext = false
            self:Advance()
        end
        
        self:Advance()
        return {kind="string", value=value}::Token
    end
    
    local function tokenMatchHelper(kind: TokenType): Token
        local token: Token = {kind=kind, value=self.current}::Token
        self:Advance()
        
        return token
    end
    
    local tokenMatches: {[string]: ()->Token} = {
        ["("] = function() return tokenMatchHelper("lparen") end,
        [")"] = function() return tokenMatchHelper("rparen") end,
        ["{"] = function() return tokenMatchHelper("lbrace") end,
        ["}"] = function() return tokenMatchHelper("rbrace") end,
        ["["] = function() return tokenMatchHelper("lbracket") end,
        ["]"] = function() return tokenMatchHelper("rbracket") end,
        ["+"] = function() return tokenMatchHelper("plus") end,
        ["-"] = function() return tokenMatchHelper("minus") end,
        ["*"] = function() return tokenMatchHelper("star") end,
        ["/"] = function() return tokenMatchHelper("slash") end,
        ["%"] = function() return tokenMatchHelper("percent") end,
        [","] = function() return tokenMatchHelper("comma") end,
        [";"] = function() return tokenMatchHelper("semicolon") end,
        ["$"] = function() return tokenMatchHelper("dollar") end,
    }
    
    if self.current then
        if not tokenMatches[self.current] then
            error(`[Lexer]-> The token '{self.current}' is not recognized.`)
        end
        
        return tokenMatches[self.current]()
    end
    
    return {kind="eof", value=""}::Token
end

return lexer