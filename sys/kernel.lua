--trashy v1

--minimal version of require that uses exact paths
local function import(path)
    if files.exists(path) then
        local datFile = files.open(path,"r")
        local dat = datFile.read("a")
        local prog = load(dat,path)
        if prog then
            local worked, progFunc = pcall(prog)
            if not worked then
                error("Failure while loading program "..path.."! Err="..progFunc);
            else
                return progFunc
            end
        else
            error("Failed to load program "..path.."!")
        end
    else
        error("File "..path.." does not exist!")
    end
end
_G.import = import

--load external APIs
local vterm = import("sys:vterm.lua")

local function sleep(time)
    if not time then
       coroutine.yield()
    else
        local newTime = chip.getUnixTime()+time
        while chip.getUnixTime() < newTime do
            coroutine.yield()
        end
    end
end

local function input()
    local str = ""
    while true do
        local n = event.getFirst("User","keyPressed")
        if n and n[1] == "keyPressed" then
            vterm.write(n[3])
            vterm.draw()
            screen.draw()
            str = str .. n[3]
            if n[2] == 13 then
                vterm.print("")
                break
            end
        else
           coroutine.yield()
        end
    end
    event.clear()
    return str
end

--application stack api
local globalApi = {}
local coroutineStack = {}

local function launchProgram(path)
    if files.exists(path) then
        local datFile = files.open(path,"r")
        local dat = datFile.read("a")
        local prog = load(dat,path,"t",globalApi)
        if prog then
            local worked, progFunc = pcall(coroutine.create,function()
                local success, response = pcall(prog)
                if not success then
                    vterm.print("Program exited with an error! Err="..response)
                end
            end)
            if not worked then
                error("Failure while loading program "..path.."! Err="..progFunc);
            else
                table.insert(coroutineStack,progFunc)
            end
        else
            error("Failed to load program "..path.."!")
        end
    else
        error("File "..path.." does not exist!")
    end
    coroutine.yield()
end

--deep copy system
local function deepCopyTable(oldTab)
    local tab = {}
    for i,v in pairs(oldTab) do
        if type(v) ~= "table" then
           tab[i] = v
        elseif i ~= "_G" then
            tab[i] = deepCopyTable(v)
        end
    end
    return tab
end

--add APIs to userland globals
globalApi = deepCopyTable(_G)
globalApi.debug = nil
globalApi.sleep = sleep
globalApi.vterm = deepCopyTable(vterm)
globalApi.print = vterm.print
globalApi.input = input
globalApi.launchProgram = launchProgram


--start the coroutine loop
table.insert(coroutineStack,coroutine.create(function()
    vterm.print("Uh oh! It looks like the shell crashed! This shouldn't happen.")
        while true do
            coroutine.yield()
        end
end))
launchProgram("sys:/shell.lua")
while true do
    local currentProg = coroutineStack[#coroutineStack]
    if currentProg == nil then
        while true do
            vterm.print("This REALLY shouldn't happen! Please report this bug to redtoast/NeetComputers!.")
           coroutine.yield()
        end
    else
        if coroutine.status(currentProg) == "dead" then
            table.remove(coroutineStack,#coroutineStack)
        elseif coroutine.status(currentProg) == "suspended" then
            coroutine.resume(currentProg)
        else
            error("what the fuck")
        end
    end
    coroutine.yield()
end
