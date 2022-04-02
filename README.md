# init.lua

Lua functions I always want to have available.

## setup

    export LUA_INIT='@/path/to/init.lua'

## functions

- `printt` to print tables on screen or to file
- `copyt` copy table
- `rpt` workaround for missing regex repititions of the form {m,n}
- `readf` read file, return table
- `writef` write table/string to file
- `eq` compares 2 values for equality
- `run` executes external command and optionally capture the output
- `log` to log function calls/returns in a logfile (uses str() helper function)

