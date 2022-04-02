# init.lua

Lua functions I always want to have available.

## background

I always had the issue that when I used the Lua interpreter, or when I wanted to write a short script, that I missed my
function to print tables, which I usually use for debugging and serializing data. Of course I could load it manually
using `require`, but I always forget that.

Don't ask me why, but after a loooong time of using Lua I discovered that there is a `LUA_INIT` environment variable that
would solve my problem. A file provided via this variable is loaded automatically when the `lua` interpreter is started.
Finally no more `require` just to get my table printing function. I decided to add some more functions, but I don't know
yet what the final list of functions will be.

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

## examples

### printt

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
	> t = {1,2,foo={"bar",4,5}}
	> printt(t)
    
	{
		[1] = 1,
		[2] = 2,
		["foo"] = 
		{
			[1] = "bar",
			[2] = 4,
			[3] = 5,
		},
	}

### copyt

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
	> t = {1,2,foo={"bar",4,5}}
	> t2= copyt(t)
	> printt(t2)
    
	{
		[1] = 1,
		[2] = 2,
		["foo"] = 
		{
			[1] = "bar",
			[2] = 4,
			[3] = 5,
		},
	}
    > print(t == t2)
	false

### rpt

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
	> s = "a bb ccc dddd eeeee"
	> s:gsub("%f[%a]".. rpt("%a",2,4) .."%f[%A]", "")
	a    eeeee	3

### readf

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > printt(readf("foo"))
    
    {
        [1] = "this",
        [2] = "is",
        [3] = "a",
        [4] = "file",
    }

### writef

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > writef(readf("foo"), "bar")
    true
    > printt(readf("bar"))

    {
        [1] = "this",
        [2] = "is",
        [3] = "a",
        [4] = "file",
    }

### eq 

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > a={1,2,3}
    > b={1,2,3}
    > eq(a,b)
    true
    > eq(1,2)
    false
    > eq(1,1)
    true
    > eq("foo", "foo")
    true

### run

    ~ ❯ lua
	Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > status,signal,code,out,err = run("ls -l", true)
    > printt(out)

    {
        [1] = "total 48",
        [2] = "-rw-r--r--  1 marcotrosi  staff   2706 Apr  2 22:06 README.md",
        [3] = "-rw-r--r--  1 marcotrosi  staff     15 Apr  2 21:56 bar",
        [4] = "-rw-r--r--  1 marcotrosi  staff     15 Apr  2 21:54 foo",
        [5] = "-rw-r--r--  1 marcotrosi  staff  12269 Apr  2 21:44 init.lua",
    } 


### log

main.lua

    function add(a,b)
        return a+b
    end

    log({Functions={["add"]=true}})

    function main()
        print(add(4,nil)) -- let it crash here
    end

    xpcall(main, log)

execution 

    ~ ❯ lua main.lua
    ~ ❯ cat /tmp/init.lua.logfile
    call add
    a number 4
    b nil nil
    ────────────────────────────────────────────────
    call add
    x string "main.lua:2: attempt to perform arithmetic on a nil value (local 'b')"
    ────────────────────────────────────────────────
    Error Message: main.lua:2: attempt to perform arithmetic on a nil value (local 'b')
    Time Stamp: Sat Apr  2 23:12:06 2022
    Lua Version: Lua 5.4
