HDD.drive("D") --Switch to the D drive
events = dofile("C:/events.lua")

local cg = _FreshGlobals()
cg.bit = nil --remove the default bit library

local cursor = "LK12;GPUIMG;8x8;0100000017100000177100001777100017777100177110000117100000000000"
cursor = GPU.imagedata(cursor)
GPU.cursor(cursor,"normal",0,0)
GPU.cursor("normal")

GPU.palt(0,false)

local apis = {
  BitAPI = {"bit"},
  FSAPI = {"fs"},
  OSAPI = {"os"},
  PeripheralAPI = {"peripheral"},
  RedstoneAPI = {"redstone","rs"},
  TermAPI = {"term"}
}

if WEB then
  apis["HTTPAPI"] = {"http"}
end

--Load the APIS
for api, names in pairs(apis) do
  CPU.cprint("Loading Peripheral: "..names[1])
  local t = dofile("C:/apis/"..api..".lua")()
  for k, name in ipairs(names) do
    cg[name] = t
  end
end

dofile("C:/apis/Events.lua")() --Register default events

cg._VERSION = "Lua 5.1"
cg._HOST = "ComputerCraft 1.79 (LIKO-12)"
--cg._CC_DEFAULT_SETTINGS = ""
cg._CC_DISABLE_LUA51_FEATURES = false
cg.load = function() error("Native Load !") end
cg.cprint = CPU.cprint

cg._G = cg

local bios = assert(HDD.load("C:/bios.lua"))
setfenv(bios,cg)

local co = coroutine.create(bios)

--Remap the palette
--            0 1 2 3  4  5  6  7 8 9  a  b c d e f
local pmap = {7,9,2,12,10,11,14,5,6,13,15,1,4,3,8,0}
for c1,c2 in ipairs(pmap) do
  GPU.pal(c1-1,c2)
end

GPU.flip = function() end --Ignore flip :/

CPU.clearEStack()
CPU.cprint("Booting CraftOS")

local lastargs = {}
while true do
  local args = {coroutine.resume(co,unpack(lastargs))}
  if not args[1] then error(tostring(args[2])) end
  if args[2] and args[2]:find(":") then --LIKO-12 Command
    local y = {}
    for i=2,#args do
      table.insert(y,args[i])
    end
    lastargs = {coroutine.yield(unpack(y))}
  else
    lastargs = events:pullEvent(args[2])
  end
end

error("OS FINISHED")