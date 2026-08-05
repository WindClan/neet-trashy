local args = {...}
if not args[1] == "THIS_IS_THE_KERNEL_PLEASE_LAUNCH_THE_SHELL" then
	vterm.print("The shell does not support nested shells.")
	return
end

local currentDisk = "hdd"
local currentDir = ""

function _G._getCurrentDisk()
	return currentDisk
end

function _G._setCurrentDisk(d)
	currentDisk = d
	currentDir = ""
end

function _G._getCurrentDir()
	return currentDir
end

function _G._setCurrentDir(d)
	currentDir = d
end

local function splitToArgs(i)
	local split = {} --for some ungodly reason gsub didn't find any matches. this is the hack to get around that
	local last = ""
	for l=1,#i do
		local let = i:sub(l,l)
		if let == " " then
			table.insert(split,last)
			last = ""
		else
			last ..= let
		end
	end
	if last ~= "" then
		table.insert(split,last)
	end
	return split
end

local function fileExists(path)
	if files.isFile(path) then
		return path
	elseif files.isFile(path..".lua") then
		return path..".lua"
	end
	return nil
end

local function resolveProgramPath(path)
	return fileExists(path) or fileExists(_SYSTEM_DISK..":/TRASHY/path/"..path) or fileExists(currentDisk..":/"..currentDir..path)
end

while true do
    vterm.write((currentDisk..":/"..currentDir.."> "):upper())
    local i = input()
	local sp =  splitToArgs(i)
	local prog = table.remove(sp,1)
	local progPath = resolveProgramPath(prog:lower())
	if not progPath then
		vterm.print("Bad command or filename - "..prog)
	else
		local suc, err = pcall(launchProgram,progPath,table.unpack(sp))
		if not suc then
			vterm.print(err)
		end
	end
end