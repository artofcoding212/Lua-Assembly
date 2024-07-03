<p align="center">
  <img src="https://github.com/artofcoding212/Lua-Assembly/blob/main/Logo.png">
</p>

<div align="center">
  <b>Lua-Assembly V1.0</b>
  <p>Created by artofcoding212 on Discord and Github.</p>
</div>

# Documentation
In this file, you will find Lua-Assembly's full documentation for the current version, which is version 1.0.

# Concepts
There are numerous concepts in Lua-Assembly that differ from x86 Assembly, like the registers.
#### The Stack
The stack in Lua-Assembly is really just an array in Luau that holds a bunch of values. Currently, there is no way to access values from the stack other than using the "pop" instruction, as that should be up 
to the registers. You can push a value to the stack using the "push" instruction.
#### Registers
In Lua-Assembly, registers are not predefined by the transpiler and are instead supposed to be defined by you using the "mkreg" definition. Because the language transpiles to Luau, x86 Assembly-like registers
are not possible, as accessing the CPU in Luau is impossible to do in a safe way from my knowledge. So, registers in Lua-Assembly are really just mutable variables that can hold values. You can change their
value by using the "mov" instruction or by popping a value off the stack into the register using the "pop" instruction.
#### Entry Point
The entry point is a function definition in which contains a function body that will be ran at the start of the program no matter what. You can define the entry point by using a function definition with
the function name of "main". Unlike x86 Assembly, the entry point *requires* a number pushed onto the stack that is the exit code before you use the "ret" instruction within the entry point function body.
The "ret" instruction is also *required* at the bottom of the entry point definition. Any exit code returned other than 0 will error.

# Statements
Every Lua-Assembly program contains statements. A statement consists of tokens separated by whitespaces and is always terminated by a semicolon. Whitespaces are made up of spaces, tabs, and formfeeds that
are not contained in a string or comment. A statement can include a comment. Empty statements containing only whitespaces are allowed.

## Comments
A comment can be appended to a statement or it can stand alone on a line. The comment is started with the hashtag character ("#") followed by the text of the comment. The comment is terminated by the
formfeed character.

## Definitions
A definition is a statement in which defines one or more variables with different values depending on the definition type. In Lua-Assembly, there are two definitions.
#### Function Definition
A function definition is a type of definition in which defines a function. The function definition starts with the "func" keyword, followed by the function name. After the function name comes a set
of braces ("{}"). Anything in-between these braces is a part of the function definition's body, which is made up of only statements. You can call a function using the "call" instruction followed by
the function's name.
#### Register Definition
A register definition is a type of definition that defines multiple registers. It is usually placed at the very top of Lua-Assembly code, as a register definition on the first line will define
the initial registers that the program will always have. A register definition starts with the "mkreg" keyword, followed by a list of identifiers containing the name of the registers you want
to define, with each identifier separated by a comma.

## Instructions
An instruction is a statement that instructs the program to do one or more tasks. As of now, Lua-Assembly supports 12 instructions.
| Instruction Name | Instruction Parameters | Instruction Description |
| ------------- | ------------- | ------------- |
| mov           | mov reg: *register*, value: *any*              | Moves the value into the register. |
| loop          | loop {body}: *body*                            | Repeats the loop body until broken with the "brk" instruction. |
| lsjmp         | lsjmp left: *any*, right: *any* {body}: *body* | If the left is less than the right, the body is ran. |
| grjmp         | grjmp left: *any*, right: *any* {body}: *body* | If the left is greater than the right, the body is ran. |
| eqjmp         | eqjmp left: *any*, right: *any* {body}: *body* | If the left is equal to the right, the body is ran. |
| push          | push value: *any*                              | Pushes the given value onto the top of the stack. |
| pop           | pop reg: *register*                            | Removes the value from the top of the stack and moves it into the register. |
| syscall       | syscall name: *ident*                          | Calls the designated system call based on the name. Arguments are passed through the stack. |
| call          | call name: *ident*                             | Calls the corresponding function that was defined. |
| raw           | raw code: *string*                             | Anything in the code string is passed on as Luau code in the transpiler. |
| ret           | ret                                            | The Luau return keyword equivalent. |
| brk           | brk                                            | The Luau break keyword equivalent. |

# Expressions
Expressions terminated by a semicolon can act as a statement; however, they will error in the transpiled code. Expressions are meant to hold values, like numbers and math problems, that can
be included in statements. As of now, Lua-Assembly supports 5 different expressions.
## Registers
The register expression starts with the percent character ("%") and is then followed by an identifier expression which is the name of the register you are trying to access. To learn more
about registers, look at "Registers" under "Concepts".
## Identifiers
The identifier expression does not have a prefix and it represents the identifier token. The identifier token starts with an alphabetic character (A-z) or an underscore ("_"). After these,
more alphabetic characters and more underscores can be included, however now numbers can be included. The identifier is commonly used in the "call" and "syscall" instructions.
## Numbers
The number expression starts with the dollar sign character ("$") and then can be followed by the minus character ("-") if you want the number to be negative. After the dollar sign or
minus character if included comes a number. It can end with the dot character (".") followed by another number to make it a floating-point number.
## Strings
The string expression simply represents the string token. The string token starts with a double quote character (""") and ends with another double quote character. Anything between these
two characters is a part of the string, except for the double quote character, as that terminates the string. However, if you want to include the double quote character within your string,
simply type the backslash character ("\") behind the double quote.
## Binary Expressions
The binary expression is like a math problem; it consists of a left expression, an operator token, and a right expression. The left and right expressions can be binary expressions to
branch off of the math problem. As of now, Lua-Assembly supports addition, subtraction, multiplication, and division. You can use the plus ("+") and minus ("-") characters as the operator
token for addition and subtraction, and you can use the asterisk ("*") and slash ("/") characters as the operator token for multiplication and division.
## Grouping Expressions
The grouping expression starts off with an open parenthesis character ("("), and ends with a closing parenthesis character (")"). In-between these two characters should be an expression.
The grouping epxression is commonly used within binary expressions, as it gives the binary expression within precedence.
