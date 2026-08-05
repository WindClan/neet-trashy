local dir = _getCurrentDir()
local disk = _getCurrentDisk()
local toProbe = ({...})[1] or ""

local finalDir = disk..":/"..dir.."/"..toProbe
if not files.isDir(finalDir) then
	finalDir = disk..":/"..dir
end

local x,y = vterm.getSize()
for _,v in pairs(files.getChildren(finalDir)) do
	local stringToPrint = v
	if files.isDir(finalDir.."/"..v) then
		stringToPrint ..= "/"
	end
	stringToPrint ..= " "
	local xPos = vterm.getCursorPos()
	if xPos+#stringToPrint > x then
		vterm.print()
	end
	vterm.write(stringToPrint)
end