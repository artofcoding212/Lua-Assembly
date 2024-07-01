<p align="center">
  <img src="https://github.com/artofcoding212/Lua-Assembly/blob/main/Logo.png">
</p>

<div align="center">
  <b>Lua-Assembly V1.0</b>
  <p>A transpiled language that has an Assembly-like grammar.</p>
  <p>Created by artofcoding212 on Discord and Github.</p>
</div>

# Introduction
Lua-Assembly is a transpiled language, meaning that the code you write will be transformed to Luau code in order for it to run specifically in Roblox. Its grammar is similar to that of x86 Assembly; however, it has a few tweaks to it, making the experience writing Lua-Assembly much better.

# Installation
#### Transpiler
To install the transpiler for Lua-Assembly in Roblox, follow the below steps:
* Get the Roblox model [here](https://create.roblox.com/store/asset/18294792797/LuaAssembly).
* Insert it into your game via the toolbox.
* You now have the transpiler!
#### VSCode Extension
As of now, the VSCode extension must be manually placed into your VSCode files, because it is not yet published. To do this, follow the below steps:
* Install the repository's main branch as a ".ZIP" folder.
* Extract the ".ZIP" folder.
* Move the highlighter folder under the extracted folder into the "C:\Users\\[USER\]\\.vscode\extensions" path (change the "\[USER\]" field to the name of the desired user you want highlighting in).
* Now, you can freely create files ending with ".luaasm" in VSCode whilst getting syntax highlighting!

# Usage
There are two methods to utilize the transpiler in Roblox.
#### Method 1
The first method is to require the model and call the "Transpile" method on your code and use the "loadstring" function on it, like shown below:
```lua
local LuaAsm = require(game.ReplicatedStorage["Lua-Assembly"]) --(Assuming the model is parented under ReplicatedStorage.)
local src: string = [[
func main{
  push "Hello, world!";
  syscall print;

  push $0;
  ret;
}
]]
loadstring(LuaAsm.Transpile(src))()
```
The only issues with this method are that it can't run on the client and that it's slower than the second method.
#### Method 2
The second method involves compiling the code directly in your command line. To do this, simply run the below command in your command line (assuming the model is parented under ReplicatedStorage):
```lua
print(require(game.ReplicatedStorage["Lua-Assembly"]).Transpile("# Lua-Assembly code here!"))
```
Now, if you navigate to the console, you should see some code that was printed. Copy this new code and paste it into a script.
