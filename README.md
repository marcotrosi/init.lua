# init.lua

Lua functions I always want to have available.


## background

I always had the issue that when I used the Lua interpreter, or when I wanted to
write a short script, that I missed my function to print tables, which I usually
use for debugging and serializing data. Of course I could load it manually using
`require`, but I always forget that.

Don't ask me why, but after a long time of using Lua I discovered that there is
a `LUA_INIT` environment variable that would solve my problem. A file provided
via this variable is loaded automatically when the `lua` interpreter is started.
Finally no more `require` just to get my table printing function. I decided to
add some more functions, but I don't know yet what the final list of functions
will be. Also I wann keep it simple and cover 80% of the use cases with 20% effort.


## setup

The setup is very easy, just put the `init.lua` file wherever you like and
assign its path to the `LUA_INIT` environment variable in your shell
configuration, for example ...

    export LUA_INIT='@/path/to/init.lua'


## overview

- `printt` to print tables on screen or to file
- `copyt` to copy tables
- `rpt` workaround for missing regex repititions of the form {m,n}
- `readf` to read-in files as tables
- `writef` to write tables/strings to file
- `eq` to compares 2 values for equality
- `run` to execute external commands and optionally capture the output
- `str` to convert any non-string type to string, and strings to quoted strings
- `log` to log function calls/returns in a logfile (uses the `str()` function)
- `maxn` to get the largest positive numerical index of the given table
- `split` to split strings at delimiter and return string parts as table
- `test` to create simple unit tests (uses the `str()` and `eq()` functions)


## documentation


### `printt(t, f)`

    t = table to print
    f = filename (optional)

#### description

A simple function to print tables or to write tables into files. Great for
debugging but also for data storage. When writing into files the `return`
keyword will be added automatically, so the tables can be loaded with `dofile()`
into a variable. The basic datatypes *table*, *string*, *number*, *boolean* and
*nil* are supported. The tables can be nested and have number and string
indices. This function has no protection when writing files without proper
permissions and when datatypes other then the supported ones are used.

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


### `copyt(t)`

    t = table to copy

#### description

This is a simple copy table function that takes a table and returns a copy. It
uses recursion so you may get trouble with cycles and too big tables. But in
most cases this function is absolutely enough.

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


### `rpt(s,m,n)`

    s   = regex atomic to repeat
    m,n = repitition range

#### description

This function provides a workaround for the *"missing"* repetition ranges as
known from other RegEx languages. E.g. if you want to match characters 2 to 4
times then you would write typically something like `%a{2,4}`, but Lua doesn't
have that, which forces us to write `%a%a%a?%a?` instead. But this is not super
readable and can get ugly quite quickly. With this function you can write
`rpt("%a",2,4)`, but has the disadvantage that it can't be directly written in
the pattern string. Ya, it's just a workaround.

#### example

    ~ ❯ lua
    Lua 5.4.3  Copyright (C) 1994-2021 Lua.org, PUC-Rio
    > s = "a bb ccc dddd eeeee"
    > s:gsub("%f[%a]".. rpt("%a",2,4) .."%f[%A]", "")
    a  eeeee  3


### `readf(f)`

    f = filename

#### description

This function reads a file and returns the content as a table with one line per
index. If the file was not readable `readf` returns nil.

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


### `writef(t, f, n, m)`

    t = table or string containing file lines
    f = filename
    n = newline character (optional, default is "\n")
    m = write mode ["w"|"a"|"w+"|"a+"] (optional, default is "w")

#### description

This function takes a table or string and writes it to a file and returns `true`
if writing was successful, otherwise `nil`. If `t` is a table it shall contain
numerical indices (1 to n) with strings as values, and no `nil` values in-between.

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


### `eq(a, b)`

    a = anything
    b = anything

#### description

This function takes two values as input and returns `true` if they are equal and
`false` if not.

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


### `run(cmd, capture)`

    cmd     = command to execute, can be string or table
    capture = optional boolean value to turn on/off capturing output, default is false. if capture is true, then the command will be surround with parantheses, just in case the cmd contains pipes.

#### description

This is kind of a wrapper function to `os.execute` and `io.popen`. The problem
with `os.execute` is that it can only return the exit status but not the command
output. And `io.popen` can provide the command output but not an exit status.
This function can do both. It will return the same return values as `os.execute`
plus two additional tables. These tables contain the command output, one line
per numeric index. Line feed and carriage return are removed from each line. The
first table contains the `stdout` stream, the second the `stderr` stream.

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


### `str(x)`

    x = anything to convert to string

#### description

This function converts anything to strings. If the input is a string then a
quoted string is returned.


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


### `log(x)`

    x         = a configuration table
    x.funcs   = a key-value table with the functionname you want to register as key, and a boolean true/false to activate logging for this function
    x.active  = boolean value to globally turn logging on/off, default is true
    x.logfile = path of the log file, default is "/tmp/init.lua.logfile"
    x.maxlog  = maximum number of log file entries, default is 20

#### description

This function has actually three purposes and the behavior changes with the
parameters. I know it's kinda dirty, but I had it in separate functions before
and I decided to put all in a single function. The user can call it only with a
configuration table or pass it to `xpcall()`. See Example. So there is only one
parameter in case of the configuration call, which shall be a table with the
following keys ...

#### example

###### main.lua

    function add(a,b)
        return a+b
    end

    log({funcs={["add"]=true}})

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


### `maxn(t)`

    t = table

#### description

This function only brings back the `table.maxn()` function from version *5.1*.
It returns the largest positive numerical index of the given table,
or zero if the table has no positive numerical indices.

The reason why such a function can be useful is because the `#` length operator
only works on sequences reliably, means when the numerical indices have no gaps.

#### example

    local a={1,2,3,4,5,6}       -- this is a sequence, #a is 6
    local b={nil,2,3,nil,nil,6} -- table with gaps, potential values of #b are 0, 3 and 6

    print(#a)      -- 6
    print(maxn(a)) -- 6
    print(#b)      -- 0, 3 or 6
    print(maxn(b)) -- 6


### `split(s, d)`

    s = string
    d = delimiter regex pattern

#### description

This function takes a string and splits it at all occurrences of the given
delimiter. The delimiter itself gets removed and each string piece will be put
in a table, which will be returned.

#### example

    ~ ❯ lua
    Lua 5.4.6  Copyright (C) 1994-2023 Lua.org, PUC-Rio
    > printt(split("long line\nthat I got\nfrom somewhere","\n"))

    {
        [1] = "long line",
        [2] = "that I got",
        [3] = "from somewhere",
    }


### `test(status, just, must)`

    status = the status of the pcall() call
    just   = the actual result
    must   = the expected result

#### description

This function is used for super simple non-fancy unit tests. It only needs 3
parameters and the rest is either extracted automatically with the Lua debug
module or is a requirement and therefore assumed to be exactly as required.
`test()` only checks if `status` is `true` and if `just` 'n' `must` are equal,
and prints accordingly a test case message with useful information.

#### example

###### main.lua

    function add(a,b)
        return a+b
    end

    function test_add(a,b,must,desc)
        local status,just = pcall(add,a,b)
        test(status,just,must)
    end

    test_add(1,2,3,"normal test")

##### execution

    ~ ❯ lua main.lua
    passed	function=add(); status=true; case=main.lua:10; test=main.lua:7'
        desc=normal test
        type=number; just=3
        type=number; must=3


### `parse()`

#### description

This function provides a quick way to parse the commandline arguments passed to the script.
It can not be fed with a configuration to describe the supported arguments, instead it only
extracts whatever the user has passed as args. Therefore it's recommended to use this
function only for rapid prototyping. The function parameters are only for internal recursive
calls and not for the users.

The following features are supported ...

- `parse()` returns a table with two keys named `"opr"` and `"opt"`.
    - `"opr"` is table with numbered indices containing the operands/positional arguments.
    - `"opt"` is table with string indices containing the parameters and options, where the string index is the name of the parameter/option.
- all parameters and options have to start with double dash `--`.
- parameter values shall be written in the assignment-form using equal sign, e.g. `--name=value`
- parameter values are stored as strings
- options are of type boolean and set to true
- arguments can also be read from file if the filename is prefixed with an @ character, e.g. `@my_opts`
- a double dash `--` indicates the end of parameters/options, all subsequent arguments are stored as operands/positional arguments.

#### example

##### main.lua

    local args = parse()
    printt(args)

##### optfile

    --input=filename
    --bingo

##### execution

    ~ ❯ lua main.lua firstoperand --booleanoption --parameter=value @optfile -- --treatedasoperand
    {
        ["opt"] =
        {
            ["parameter"] = "value",
            ["booleanoption"] = true,
            ["bingo"] = true,
            ["input"] = "filename",
        },
        ["opr"] =
        {
            [1] = "firstoperand",
            [2] = "--treatedasoperand",
        },
    }

