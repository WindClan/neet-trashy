--trashy v1

--minimal version of require that uses exact paths
local function import(path)
    if files.exists(path) then
        local datFile = files.open(path,"r")
        local dat = datFile.read("a")
        local prog,err = load(dat,path)
        if prog then
            local worked, progFunc = pcall(prog)
            if not worked then
                error("Failure while loading program "..path.."! Err="..progFunc);
            else
                return progFunc
            end
        else
            error("Failed to load program "..path.."! Err="..err);
        end
    else
        error("File "..path.." does not exist!")
    end
end
_G.import = import

local vterm = import("sys:vterm.lua")

local function sleep(time)
    local start = chip.getUnixTime()
    if not time then
       yield()
    else
        local newTime = chip.getUnixTime()+time
        while chip.getUnixTime() < newTime do
            yield()
        end
    end
    return chip.getUnixTime()-start
end
local function input()
    local str = ""
    while true do
        local sizeX,sizeY = vterm.getSize()
        local posX,posY = vterm.getCursorPos()
        local n = yield()["user"]
        if n and n[1] == "keyPressed" then
            if n[2] == 13 then
                vterm.print("")
                break
            elseif n[2] == 8 then
                if #str ~= 0 then
                    str = str:sub(1,#str-1)
                    posX = posX - 1
                    if posX == 0 then
                        posY = posY - 1
                        posX = sizeX
                    end
                    vterm.setCursorPos(posX,posY)
                    vterm.setChar("",posX,posY)
                    vterm.draw()
                end
            else
                if posX > sizeX then
                    posX = 1
                    posY = posY + 1
                    vterm.setCursorPos(posX,posY)
                    if posY > sizeY then
                        vterm.scroll(1)
                    end
                    vterm.draw()
                end
                vterm.write(n[3])
                vterm.draw()
                screen.draw()
                str = str .. n[3]
            end
        end
    end
    return str
end

_G.vterm = vterm
_G.sleep = sleep
_G.input = input
_G.yield = coroutine.yield
_G.log = print

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
_G.table.copy = deepCopyTable

--driver stack
--TODO: actually implement
local driverGlobalApi = {}
local driverStack = {}
table.insert(driverStack,coroutine.create(function()
    while true do
        coroutine.yield()
    end
end))

--the thing that returns the next event
local cats = {
    "unlabeled",
    "user",
    "system",
    "network",
    "peripheral",
    "compatibility"
}
local function getNextEvent()
    local ret = {}
    for _,v in ipairs(cats) do
         ret[v] = event.getFirst(v)
    end
    return ret
end

--add APIs to userland globals
globalApi = deepCopyTable(_G)
globalApi.debug = nil
globalApi.event = nil
globalApi.peripheral = nil
globalApi.sleep = sleep
globalApi.print = vterm.print
globalApi.launchProgram = launchProgram

--add APIs to userland globals
driverGlobalApi = deepCopyTable(_G)
driverGlobalApi.debug = nil
driverGlobalApi.event = nil
driverGlobalApi.vterm = nil
driverGlobalApi.sleep = sleep
driverGlobalApi.launchProgram = launchProgram

--start the coroutine loop
table.insert(coroutineStack,coroutine.create(function()
    vterm.print("Uh oh! It looks like the shell crashed! This shouldn't happen.")
        while true do
            coroutine.yield()
        end
end))
launchProgram("sys:/shell.lua")

local withoutYield = 0
while true do
    local currentProg = coroutineStack[#coroutineStack]
    local currentEvent = getNextEvent()
    if currentProg == nil then
        while true do
            vterm.print("This REALLY shouldn't happen! Please report this bug to redtoast/NeetComputers!")
           coroutine.yield()
        end
    else
        if coroutine.status(currentProg) == "dead" then
            table.remove(coroutineStack,#coroutineStack)
        elseif coroutine.status(currentProg) == "suspended" then
            coroutine.resume(currentProg,currentEvent)
        else
            error("Cosmic ray detected in program stack! coroutine:"..coroutine.status(currentProg))
        end
    end
    for i,v in pairs(driverStack) do
        if coroutine.status(v) == "dead" then
            table.remove(driverStack,i)
        elseif coroutine.status(v) == "suspended" then
            coroutine.resume(v,currentEvent)
        else
            error("Cosmic ray detected in driver stack! coroutine:"..coroutine.status(v))
        end
    end
    if #currentEvent == 0 or withoutYield > 99 then
        coroutine.yield()
        withoutYield = 0
    else
        withoutYield = withoutYield + 1
    end
end
