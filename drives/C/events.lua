local events = {}

events.lk = {} --LIKO-12 events registry
events.cc = {} --Computercraft events stack
events.c = 0 --Events counter

--Register a LIKO-12 event
function events:register(event,func)
  if not self.lk[event] then self.lk[event] = {} end
  table.insert(self.lk[event],func)
end

--Trigger a computercraft event
function events:trigger(name,...)
  table.insert(self.cc,{name=name, args={...}})
end

--Pull a CC event from the stack
local function pullCC(filter)
  if #events.cc > events.c then
    for i=events.c+1, #events.cc do
      local event = events.cc[i]
      if event and ((not filter) or (event.name == filter)) then
        events.cc[i] = false
        if not filter then events.c = events.c + 1 end
        return true, {event.name, unpack(event.args)}
      end
    end
  end
end

--Pull a CC event form the stack
function events:pullEvent(filter)
  --Pull a CC event from the stack
  local found, args = pullCC(filter)
  if found then return args end
  
  --Pull LIKO-12 events
  for event, a,b,c,d,e,f in CPU.pullEvent do
    local oldcc = #self.cc
    if self.lk[event] then
      for k,f in ipairs(self.lk[event]) do
        f(a,b,c,d,e,f)
      end
    end
    
    if #self.cc > oldcc then
      local found, args = pullCC(filter)
      if found then return args end
    end
  end
end

return events