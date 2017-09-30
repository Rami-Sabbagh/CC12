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
  TermAPI = {"term"},
  LIKOAPI = {"LIKO12"}
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

--Upload the palette
local palette = {
  {240, 240, 240},
	{242, 178, 51},
	{229, 127, 216},
	{153, 178, 242},
	{222, 222, 108},
	{127, 204, 25},
	{242, 178, 204},
	{76, 76, 76},
	{153, 153, 153},
	{76, 153, 178},
	{178, 102, 229},
	{51, 102, 204},
	{127, 102, 76},
	{87, 166, 78},
	{204, 76, 76},
	{25, 25, 25},
}
for k,v in ipairs(palette) do
  GPU.colorPalette(k-1,unpack(v))
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