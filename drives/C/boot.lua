local HandledAPIS = ... --select(2,...)

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
for peripheral,funcs in pairs(HandledAPIS) do
  _G[peripheral] = funcs
end

function dofile(path)
  return assert(HDD.load(path))()
end

dofile("C:/kernel.lua")