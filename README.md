# Super Mario World NEAT
> Watch as the program learns how to play Super Mario World!

<br/>

![Example run](.github/demo.gif?raw=true)

**FEATURES**

- Input detection system that registers blocks, enemy sprites, and other obstacles
- Genome creation, complete with inheritance and genetic mutations
- Natural selection mechanic that mimics real-world speciation and evolution

<br/>

**SETUP**

The program requires [Bizhawk emulator][1]. Download and install it. You will also need a Super Mario World (USA) ROM for the SNES.

Run the ROM using Bizhawk. Open main.lua in Bizhawk's Lua console.

If you want to run the included unit tests, ensure the script module is included in your LUA path.

<br/>

**Resources I found helpful**

I must emphasize that this project was HEAVILY based on this [video][2] by Sethbling.

[1]: <http://tasvideos.org/BizHawk.html> "Bizhawk official page"
[2]: <https://www.youtube.com/watch?v=qv6UVOQ0F44> "Sethbling's MarI/O"

Besides the aforementioned video, I used the following sources:
- http://nn.cs.utexas.edu/downloads/papers/stanley.ec02.pdf
- http://tasvideos.org/Bizhawk/LuaFunctions.html
- https://www.smwcentral.net/?p=memorymap&game=smw&region=ram
- https://chortle.ccsu.edu/java5/Notes/chap85/ch85_12.html
- https://www.lua.org/docs.html
- https://luaunit.readthedocs.io/en/latest/