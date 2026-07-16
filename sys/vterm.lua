-- virtual terminal for trashy
-- since its vital to literally everything the OS does it's not a driver.
local sizeX1,sizeY1 = screen.getSize()
local termSizeX, termSizeY = math.floor((sizeX1-1)/20)*20, math.floor((sizeY1-1)/24)*24
local topX, topY = (sizeX1/2)-(termSizeX/2), (sizeY1/2)-(termSizeY/2)
local termTable = {}
for i=1,termSizeY/24 do
    local a = {}
    for i1=1,termSizeX/20 do
        table.insert(a," ")
    end
    table.insert(termTable,a)
end

local drawChar = import("sys:/font.lua")
local x,y = 1,1
local sizeX, sizeY = termSizeX/20, termSizeY/24
local vterm = {}
function vterm.drawChar(x,y,c)
    drawChar(topX+((x-1)*20)+1,topY+((y-1)*24)+1,c,220,220,200)
end
function vterm.draw()
    screen.fill(1,1,sizeX1,sizeY1,0,0,0)
    for y,v in pairs(termTable) do
        for x,c in pairs(v) do
            vterm.drawChar(x,y,c)
        end
    end
    screen.draw()
end

function vterm.setChar(c,x1,y1)
    if not x1 then
        x1 = x
    end
    if not y1 then
        y1 = y
    end
    if c == "" then
        c = " "
    end
    if termTable[y1] and termTable[y1][x1] then
        termTable[y1][x1] = c:sub(1,1)
        vterm.drawChar(x1,y1,c:sub(1,1))
        screen.draw()
    end
end

function vterm.setCursorPos(x1,y1)
    x,y = x1,y1
end

function vterm.getCursorPos()
    return x,y
end

function vterm.getSize()
    return sizeX,sizeY
end

function vterm.write(str)
    local split = {}
    for i=1,#str do
        table.insert(split,str:sub(i,i))
    end
    for i,v in pairs(split) do
        if termTable[y][x] then
            termTable[y][x] = v
            vterm.drawChar(x,y,v)
        end
        x = x + 1
    end
    screen.draw()
end

function vterm.print(str)
    local split = {}
    for i=1,#str do
        table.insert(split,str:sub(i,i))
    end
    for i,v in pairs(split) do
        if termTable[y][x] then
            termTable[y][x] = v
        end
        x = x + 1
        if x > sizeX then
            y = y + 1
            x = 1
            if y > sizeY then
                y = sizeY
                vterm.scroll(1);
            end
        end
    end
    x = 1
    y = y + 1
    if y > sizeY then
        vterm.scroll(1);
    end
    vterm.draw()
end

function vterm.scroll(i)
    for i1=i, sizeY do
        termTable[i1-i+1] = termTable[i1+1]
    end
    for i1=sizeY-i+1,sizeY do
        local a = {}
        for i1=1,sizeX do
            table.insert(a," ")
        end
        termTable[i1] = a
    end
    y = y-i
    if y < 1 then
        y = 1;
    end
    vterm.draw()
end

return vterm
