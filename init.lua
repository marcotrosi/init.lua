-- printt <<<
--[[
A simple function to print tables or to write tables into files.
Great for debugging but also for data storage.
When writing into files the 'return' keyword will be added automatically,
so the tables can be loaded with 'dofile()' into a variable.
The basic datatypes table, string, number, boolean and nil are supported.
The tables can be nested and have number and string indices.
This function has no protection when writing files without proper permissions and
when datatypes other then the supported ones are used.

t = table
f = filename (optional)
--]]
function printt(t, f)

   local function printTableHelper(obj, cnt)

      local cnt = cnt or 0

      if type(obj) == "table" then

         io.write("\n", string.rep("\t", cnt), "{\n")
         cnt = cnt + 1

         for k,v in pairs(obj) do

            if type(k) == "string" then
               io.write(string.rep("\t",cnt), '["'..k..'"]', ' = ')
            end

            if type(k) == "number" then
               io.write(string.rep("\t",cnt), "["..k.."]", " = ")
            end

            printTableHelper(v, cnt)
            io.write(",\n")
         end

         cnt = cnt-1
         io.write(string.rep("\t", cnt), "}")

      elseif type(obj) == "string" then
         io.write(string.format("%q", obj))

      else
         io.write(tostring(obj))
      end 
   end

   if f == nil then
      printTableHelper(t)
   else
      local h = io.output(f)
      io.write("return")
      printTableHelper(t)
      h:close()
      io.output(io.stdout)
   end
end -- >>>
-- copyt <<<
--[[
This is a simple copy table function. It uses recursion so you may get trouble
with cycles and too big tables. But in most cases this function is absolutely enough.

t = table to copy
--]]
function copyt(t)

   if type(t) ~= "table" then return nil end

   local Copy_t = {}
 
   for k,v in pairs(t) do
      if type(v) == "table" then
         Copy_t[k] = copyt(v)
      else
         Copy_t[k] = v
      end
   end
 
   return Copy_t
end -- >>>
-- rpt <<<
--[[
remove words with length 2 to 4
s = "a bb ccc dddd eeeee"
print(s:gsub("%f[%a]".. rpt("%a",2,4) .."%f[%A]", ""))
if Lua had classic repitions for regex then the line would be
print(s:gsub("%f[%a]%a{2,4}%f[%A]", ""))

s   = regex atomic to repeat
m,n = repitition range
--]]
function rpt(s,m,n)
   return s:rep(m) .. (s..'?'):rep(n-m)
end -- >>>
-- readf <<<
--[[
readf() reads a file and returns the content as a table with one line per index.
if the file was not readable readf returns nil.

f = filename
--]]
function readf(f)

   if (type(f) ~= "string") then
      return nil
   end

   local File_t = {}
   local File_h = io.open(f)

   if File_h then
      for l in File_h:lines() do
         table.insert(File_t, (string.gsub(l, "[\n\r]+$", "")))
      end
      File_h:close()
      return File_t
   end

   return nil
end -- >>>
-- writef <<<
--[[
writef() takes a table or string and writes it to a file and returns true if writing was successful, otherwise nil.
If t is a table it shall contain numerical indices (1 to n) with strings as values, and no nil values in-between.

t = table or string containing file lines
f = filename
n = newline character (optional, default is "\n")
m = write mode ["w"|"a"|"w+"|"a+"] (optional, default is "w")
--]]
function writef(t, f, n, m)

   local n = n or "\n"
   local m = m or "w"

   if (type(t) ~= "table") and (type(t) ~= "string")              then return nil end
   if (type(f) ~= "string")                                       then return nil end
   if (type(n) ~= "string")                                       then return nil end
   if (type(m) ~= "string") or (not string.match(m, "^[wa]%+?$")) then return nil end

   local File_h = io.open(f, m)
   if File_h then
      if (type(t) == "table") then
         for _,l in ipairs(t) do
            File_h:write(l)
            File_h:write(n)
         end
      else
         File_h:write(t)
      end
      File_h:close()
      return true
   end
   return nil
end -- >>>
-- eq <<<
--[[
This function takes 2 values as input and returns true if they are equal and false if not.

a and b can numbers, strings, booleans, tables and nil.
--]]
function eq(a,b)

   local function isEqualTable(t1,t2) -- <<<

      if t1 == t2 then
         return true
      end

      for k,v in pairs(t1) do

         if type(t1[k]) ~= type(t2[k]) then
            return false
         end

         if type(t1[k]) == "table" then
            if not isEqualTable(t1[k], t2[k]) then
               return false
            end
         else
            if t1[k] ~= t2[k] then
               return false
            end
         end
      end

      for k,v in pairs(t2) do

         if type(t2[k]) ~= type(t1[k]) then
            return false
         end

         if type(t2[k]) == "table" then
            if not isEqualTable(t2[k], t1[k]) then
               return false
            end
         else
            if t2[k] ~= t1[k] then
               return false
            end
         end
      end

      return true
   end -- >>>

   if type(a) ~= type(b) then
      return false
   end

   if type(a) == "table" then
      return isEqualTable(a,b)
   else
      return (a == b)
   end
end -- >>>
-- run <<<
--[[
This is kind of a wrapper function to os.execute and io.popen.
The problem with os.execute is that it can only return the
exit status but not the command output. And io.popen can provide
the command output but not an exit status. This function can do both.
It will return the same return valus as os.execute plus two additional tables.
These tables contain the command output, 1 line per numeric index.
Line feed and carriage return are removed from each line.
The first table contains the stdout stream, the second the stderr stream.

cmd     = command to execute, can be string or table
capture = optional boolean value to turn on/off capturing output, default is false.
          if capture is true, then the command will be surround with parantheses, just in case the cmd contains pipes.
--]]
function run(cmd, capture)
 
   if (type(cmd) ~= "string") and (type(cmd) ~= "table") then return nil end
 
   local OutFile_s = "/tmp/init.lua.run.out"
   local ErrFile_s = "/tmp/init.lua.run.err"
   local Command_s
   local Out_t
   local Err_t

   if type(cmd) == "table" then
      Command_s = table.concat(cmd, " ")
   else
      Command_s = cmd
   end

   if capture then
      Command_s = "( " .. Command_s .. " )" .. " 1> " .. OutFile_s .. " 2> " .. ErrFile_s
   end
 
   local Status_b, Signal_n, ExitCode_n = os.execute(Command_s)
  
   if capture then
      Out_t = readf(OutFile_s)
      Err_t = readf(ErrFile_s)
      os.remove(OutFile_s)
      os.remove(ErrFile_s)
      return Status_b, Signal_n, ExitCode_n, Out_t, Err_t
   end
 
   return Status_b, Signal_n, ExitCode_n
end -- >>>
-- str <<<
--[[
This function converts tables, functions, ... to strings.
If the input is a string then a quoted string is returned.

x = input to convert to string
--]]
function str(x)
   if type(x) == "table" then
      local ret_t = {}
      local function convertTableToString(obj, cnt) -- <<<
         local cnt=cnt or 0
         if type(obj) == "table" then
            table.insert(ret_t, "\n" .. string.rep("\t",cnt) .. "{\n")
            cnt = cnt+1
            for k,v in pairs(obj) do
               if type(k) == "string" then
                  table.insert(ret_t, string.rep("\t",cnt) .. '["' .. k .. '"] = ')
               end
               if type(k) == "number" then
                  table.insert(ret_t, string.rep("\t",cnt) .. "[" .. k.. "] = ")
               end
               convertTableToString(v, cnt)
               table.insert(ret_t, ",\n")
            end
            cnt = cnt-1
            table.insert(ret_t, string.rep("\t",cnt) .. "}")
         elseif type(obj) == "string" then
            table.insert(ret_t, string.format("%q",obj))
         else
            table.insert(ret_t, tostring(obj))
         end 
      end -- >>>
      convertTableToString(x)
      return table.concat(ret_t)
   elseif type(x) == "function" then
      local status, result = pcall(string.dump, x, true)
      if status then
         return result
      else
         return "not dumpable function"
      end
   elseif type(x) == "string" then
      return string.format("%q", x)
   else
      return tostring(x)
   end
end -- >>>
-- log <<<
--[[
This function has actually 3 purposes and the behavior changes with the parameters.
I know it's kinda dirty, but I had it in separate functions before and I decided to put all in a single function.

The user can call it only with a configuration table or pass it to `xpcall()`. See Example.

::. CONFIG .::
funcs   = a key-value table with the functionname you want to register as key, and a boolean true/false to activate logging for this function
active  = boolean value to globally turn logging on/off, default is true
logfile = path of the log file, default is "/tmp/init.lua.logfile"
maxlog  = maximum number of log file entries, default is 20

::. EXAMPLE .::
function add(a,b)
    return a+b
end
log({funcs={["add"]=true}})
function main()
    print(add(4,nil)) -- let it crash here
end
xpcall(main, log)
--]]
function log(x)
   if (type(x) == "string") and ((x=="call") or (x=="tail call") or (x=="return") or (x=="line") or (x=="count")) then -- parameter is string, means function was called via debug hook, means log function call/return information <<<
      -- TODO check how to handle functions as parameter ?
      -- TODO check how to handle elipse ... (nameless parameters) ?
      Info_t     = debug.getinfo(2, "n")
      Function_s = Info_t.name

      if _G.Log.funcs[Function_s] then

         local Data = {Function=Function_s, Event=x}
         local UpValueCnt_n = 1
         local UpValues_t = {}

         while true do

            Name, Value = debug.getlocal(2, UpValueCnt_n)

            if (Name == nil) then
               break
            end

            if (x == "call") and (Name == '(temporary)') then
               break
            end

            table.insert(UpValues_t, {["Name"]=Name, ["Type"]=type(Value), ["Value"]=str(Value)})

            UpValueCnt_n = UpValueCnt_n + 1
         end

         if (x == "return") then
            table.remove(UpValues_t) -- remove last entry, it's a Lua internal
         end
         Data.UpValues = UpValues_t

         table.insert(_G.Log.Data, Data)

         if (#(_G.Log.Data) > (_G.Log.maxlog or 20)) and (_G.Log.maxlog ~= 0) then
            table.remove(_G.Log.Data, 1)
         end
      end
      -- >>>
   elseif type(x) == "table"  then -- parameter is table, means function was called by user, means do configuration <<<

      if _G.Log == nil then
         _G.Log = {Data={}}
      end
      _G.Log.active  = x.active  or _G.Log.active  or true                    -- logging on/off
      _G.Log.logfile = x.logfile or _G.Log.logfile or "/tmp/init.lua.logfile" -- name of the log file
      _G.Log.maxlog  = x.maxlog  or _G.Log.maxlog  or 20                      -- maximum number of log entries, set to 0 to log everything, default is 20
      _G.Log.funcs   = x.funcs   or _G.Log.funcs   or {}                      -- table of registered functions
      if _G.Log.active then
         debug.sethook(log, "cr") -- c and/or r
      end
      -- >>>
   else -- assuming function was called from xpcall, means write logfile <<<

      if (_G.Log == nil) or (_G.Log.active ~= true) then
         return
      end

      local LogFile_h = io.open(_G.Log.logfile, "w+")
      if not LogFile_h then
         io.stderr:write("\nlog error: could not open '".._G.Log.logfile.."' for writing\n")
         return
      end 

      for i,v in ipairs(_G.Log.Data or {}) do

         LogFile_h:write(v.Event .. " " .. v.Function,"\n")

         for _,p in ipairs(v.UpValues) do
            LogFile_h:write("   "..p.Name.." "..p.Type.." "..p.Value.."\n")
         end

         LogFile_h:write("────────────────────────────────────────────────\n")
      end

      LogFile_h:write(string.format("Error Message: %s\n" , x))
      LogFile_h:write(string.format("Time Stamp: %s\n" , os.date()))
      LogFile_h:write(string.format("Lua Version: %s\n", _VERSION ))
      LogFile_h:close()

      io.stderr:write("oh oh, something unforeseen happened. Looks like you found a bug.\n")
      io.stderr:write("the error message is: " .. x .. "\n")
      io.stderr:write("if you want you can report your actions along with the logfile '".._G.Log.logfile.."'.\n")
      io.stderr:write("thank you very much and my apologies for any inconveniences this may have caused.\n")

   end -- >>>
end -- >>>
-- maxn <<<
--[[
This function only brings back the table.maxn() function from version 5.1.
It returns the largest positive numerical index of the given table,
or zero if the table has no positive numerical indices.

The reason why such a function can be useful is because the `#` length operator
only works on sequences, means when the numerical indices have no gaps.

t = table
--]]
function maxn(t)
   local n = 0
   for i,v in pairs(t) do
      if type(i) == 'number' then
         n = math.max(n,i)
      end
   end
   return n
end -- >>>
-- split <<<
--[[
split() takes a string and splits it at all occurrences of the given delimiter.
The delimiter itself gets removed and each string piece will be put in a table, which will be returned.

s = string
d = delimiter (regex pattern)
--]]
function split(s, d)

   if (type(s) ~= "string") or (type(d) ~= "string") then
      return nil
   end

   local Result_t = {}

   if s == "" then
      return Result_t
   end

   if d == "" then
      table.insert(Result_t, s)
      return Result_t
   end
 
   local Start = 1
   local SplitStart, SplitEnd = string.find(s, d, Start)
 
   while SplitStart do
      table.insert(Result_t, string.sub(s, Start, SplitStart-1))
      Start = SplitEnd + 1
      SplitStart, SplitEnd = string.find(s, d, Start)
   end
   table.insert(Result_t, string.sub(s, Start)) -- insert remaining string into table
 
   return Result_t
end
-- >>>
-- test <<<
--[[
This function is used for super simple non-fancy unit tests.
It only needs 3 parameters and the rest is either extracted automatically with the Lua debug module
or is a requirement and therefore assumed to be exactly as required.
test() only checks if status is true and if just 'n' must are equal, and prints accordingly a test case message with useful information.

status = the status of the pcall() call
just   = the actual result
must   = the expected result

::. EXAMPLE .::
function add(a,b)
   return a+b
end

function test_add(a,b,must,desc)
   local status,just = pcall(add,a,b)
   test(status,just,must)
end

test_add(1,2,3,"normal test")

::. REQUIREMENTS .::
- the name of your testing-function shall be the name of your tested-function but prefixed with "test_". In the example the tested-function is "add" so the testing function is "test_add".
- the last parameter of your testing-function shall be a string containing the test case description. In the example it's the "desc" parameter of "test_add(....., desc)".
- a quasi-requirement is that you call your tested-function through pcall() which catches potential crashes.
--]]
function test(status,just,must)
   local result = "\27[32mpassed\27[0m"
   if (not status) or (not eq(just,must)) then result = "\27[31mfailed\27[0m" end
   local i2 = debug.getinfo(2)
   local i3 = debug.getinfo(3)
   print(result, string.format("function=%s(); status=%s; case=%s:%d; test=%s:%d'",
                                string.sub(i2.name,6),
                                               str(status),
                                                          i3.short_src, i3.currentline,
                                                                      i2.short_src, i2.currentline))
   print("", string.format("%s=%s", debug.getlocal(2, i2.nparams)))
   print("", string.format("type=%s; just=%s", type(just), str(just)))
   print("", string.format("type=%s; must=%s", type(must), str(must)))
end
-- >>>
-- parse <<<
--[[
This function provides a quick way to parse the commandline arguments passed to the script.
It can not be fed with a configuration to describe the supported arguments, instead it only
extracts whatever the user has passed as args. Therefore it's recommended to use this
function only for rapid prototyping.

The following features are supported ...
- parse() returns a table with two keys named "opr" and "opt".
   - "opr" is table with numbered indices containing the operands/positional arguments.
   - "opt" is table with string indices containing the parameters and options, where the string index is the name of the parameter/option.
- all parameters and options have to start with double dash --.
- parameter values shall be written in the assignment-form using equal sign, e.g. --name=value
- parameter values are stored as strings
- options are of type boolean and set to true
- arguments can also be read from file if the filename is prefixed with an @ character, e.g. @my_opts
- a double dash -- indicates the end of parameters/options, all subsequent arguments are stored as operands/positional arguments.

::. EXAMPLE .::

local args = parse()
printt(args)

> lua main.lua firstoperand --booleanoption --parameter=value @optfile -- --treatedasoperand
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
--]]
function parse(args, result, eo)
   local Args      = args or arg
   local Result    = result or {opr={}, opt={}}
   local EndOfOpts = eo or false
   for _,a in ipairs(Args) do
      if string.sub(a,1,1) == "@" then
         local ArgsFile = string.sub(a,2)
         local FileArgs = readf(ArgsFile)
         if not FileArgs then
            print("failed to read args from file '" .. ArgsFile .. "'")
            goto continue
         end
         parse(FileArgs, Result, EndOfOpts)
         goto continue
      end
      if EndOfOpts then -- everything is an operand
         table.insert(Result.opr, a)
      else
         if a == "--" then
            EndOfOpts = true
            goto continue
         end
         if string.sub(a,1,2) == "--" then
            local Parameter,Value = string.match(string.sub(a,3), "^([^=]+)=(.*)$")
            if Parameter then
               Result.opt[Parameter] = Value
            else
               Result.opt[string.sub(a,3)] = true
            end
            goto continue
         end
         table.insert(Result.opr, a)
      end
      ::continue::
   end
   return Result
end
-- >>>
-- vim: fmr=<<<,>>> fdm=marker
