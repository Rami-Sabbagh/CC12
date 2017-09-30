--Backup the fresh clean globals
local function copy(t)
  local new = {}
  for k,v in pairs(t) do
    if type(v) == "table" then
      if k ~= "_G" then new[k] = copy(v) end
    else
      new[k] = v
    end
  end
  return new
end

local freshglob = copy(_G)
function _FreshGlobals()
  return copy(freshglob)
end

--Building the peripherals APIs--
local _,directapi = coroutine.yield("BIOS:DirectAPI"); directapi = directapi or {}
local _,perlist = coroutine.yield("BIOS:listPeripherals")
for peripheral,funcs in pairs(perlist) do
  _G[peripheral] = {}
  local holder = _G[peripheral]
  
  for _,func in ipairs(funcs) do
    if directapi[peripheral] and directapi[peripheral][func] then
      holder[func] = directapi[peripheral][func]
    else
      local command = peripheral..":"..func
      holder[func] = function(...)
        local args = {coroutine.yield(command,...)}
        if not args[1] then return error(args[2]) end
        local nargs = {}
        for k,v in ipairs(args) do
          if k >1 then table.insert(nargs,k-1,v) end
        end
        return unpack(nargs)
      end
    end
  end
end

function dofile(path)
  return assert(HDD.load(path))()
end

dofile("C:/kernel.lua")