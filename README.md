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

## overview

- `printt` to print tables on screen or to file
- `copyt` copy table
- `rpt` workaround for missing regex repititions of the form {m,n}
- `readf` read file, return table
- `writef` write table/string to file
- `eq` compares 2 values for equality
- `run` executes external command and optionally capture the output
- `str` converts any non-string type to string, and strings to quoted strings
- `log` to log function calls/returns in a logfile (uses the `str()` function)

## documentation

### printt

#### description

A simple function to print tables or to write tables into files. Great for debugging but also for data storage. When
writing into files the `return` keyword will be added automatically, so the tables can be loaded with `dofile()` into a
variable. The basic datatypes table, string, number, boolean and nil are supported. The tables can be nested and have
number and string indices. This function has no protection when writing files without proper permissions and when
datatypes other then the supported ones are used.

    t = table
    f = filename (optional)

#### example

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

#### description

This is a simple copy table function. It uses recursion so you may get trouble
with cycles and too big tables. But in most cases this function is absolutely enough.

    t = table to copy

#### example

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

#### description

This function provides a workaround for the "missing" repetition ranges as known from other RegEx languages.
E.g. if you want to match characters 2 to 4 times then you would write typically something like `%a{2,4}`, but
Lua doesn't have that, which forces us to write `%a%a%a?%a?` instead. But this is not super readable and can get ugly
quite quickly. With this function you can write `rpt("%a",2,4)`, but has the disadvantage that it can't be directly
written in the pattern string. Ya it's just a workaround.

    s   = regex atomic to repeat
    m,n = repitition range

#### example

    ~ ❯ lua
    Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > s = "a bb ccc dddd eeeee"
    > s:gsub("%f[%a]".. rpt("%a",2,4) .."%f[%A]", "")
    a  eeeee  3

### readf

#### description

`readf` reads a file and returns the content as a table with one line per index.
if the file was not readable `readf` returns nil.

    f = filename

#### example

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

#### description

`writef` takes a table or string and writes it to a file and returns `true` if writing was successful, otherwise `nil`.
If `t` is a table it shall contain numerical indices (1 to n) with strings as values, and no `nil` values in-between.

    t = table or string containing file lines
    f = filename
    n = newline character (optional, default is "\n")
    m = write mode ["w"|"a"|"w+"|"a+"] (optional, default is "w")

#### example

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

#### desription

This function takes 2 values as input and returns true if they are equal and false if not.

    a = anything
    b = anything

#### example

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

#### description

This is kind of a wrapper function to `os.execute` and `io.popen`.
The problem with `os.execute` is that it can only return the
exit status but not the command output. And `io.popen` can provide
the command output but not an exit status. This function can do both.
It will return the same return valus as `os.execute` plus two additional tables.
These tables contain the command output, 1 line per numeric index.
Line feed and carriage return are removed from each line.
The first table contains the `stdout` stream, the second the `stderr` stream.

    cmd     = command to execute, can be string or table
    capture = optional boolean value to turn on/off capturing output, default is false. if capture is true, then the command will be surround with parantheses, just in case the cmd contains pipes.

#### example

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

### str

#### description

This function converts anything to strings.
If the input is a string then a quoted string is returned.

    x = input to convert to string

#### example

    ~ ❯ lua
    Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > print(str(nil), type(str(nil)), type(nil))
    nil string nil
    > print(str(true), type(str(true)), type(true))
    true string boolean
    > print(str(123), type(str(123)), type(123))
    123 string number
    > print(str({1,2,3}), type(str({1,2,3})), type({1,2,3}))
    {
      [1] = 1,
      [2] = 2,
      [3] = 3,
    } string table
    > print(str("foo"), type(str("foo")), type("foo"))
    "foo" string string


### log

#### description

This function has actually 3 purposes and the behavior changes with the parameters.
I know it's kinda dirty, but I had it in separate functions before and I decided to put all in a single function.
The user can call it only with a configuration table or pass it to `xpcall()`. See Example.
So there is only 1 parameter in case of the configuration call, which shall be a table with the following keys ...

    Functions = a key-value table with the functionname you want to register as key, and a boolean true/false to activate logging for this function
    IsOn      = boolean value to globally turn logging on/off, default is true
    File      = path of the log file, default is "/tmp/init.lua.logfile"
    Max       = maximum number of log file entries, default is 20

#### example

###### main.lua

    function add(a,b)
        return a+b
    end

    log({Functions={["add"]=true}})

    function main()
        print(add(4,nil)) -- let it crash here
    end

    xpcall(main, log)

###### execution 

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

