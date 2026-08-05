local datFile = files.open("hdd:/TRASHY/kernel.lua","r")
local dat = datFile.read("a")
local prog,err = load(dat,"KERNEL")
if not prog then
	chip.crash(err)
end
prog("hdd")