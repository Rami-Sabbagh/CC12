local keymap = dofile("C:/keymap.lua")

return function() --Hook default events
  --Keyboard shortcuts
  local terminate = 0
  
  events:register("update",function(dt)
    if Keyboard.isKDown("lctrl","rctrl") and Keyboard.isKDown("t") then
      terminate = terminate + dt
      if terminate >= 1 then
        events:trigger("terminate")
        terminate = 0
      end
    else
      terminate = 0
    end
  end)
  
  local shutdown = 0
  
  events:register("update",function(dt)
    if Keyboard.isKDown("lctrl","rctrl") and Keyboard.isKDown("s") then
      shutdown = shutdown + dt
      if shutdown >= 1 then
        CPU.shutdown()
        shutdown = 0
      end
    else
      shutdown = 0
    end
  end)
  
  local reboot = 0
  
  events:register("update",function(dt)
    if Keyboard.isKDown("lctrl","rctrl") and Keyboard.isKDown("r") then
      reboot = reboot + dt
      if reboot >= 1 then
        CPU.reboot()
        reboot = 0
      end
    else
      reboot = 0
    end
  end)
  
  events:register("keypressed",function(key,isrepeat)
    if k == "v" and Keyboard.isKDown("lctrl","rctrl") then
      events:trigger("paste",clipboard())
    end
  end)
  
  --Other events
  events:register("textinput",function(t)
    events:trigger("char",t)
  end)
  
  events:register("keypressed",function(key,isrepeat)
    local id = keymap.toCode(key)
    if id then
      events:trigger("key",id,isrepeat)
    else
      CPU.cprint("Unknown key: "..key)
    end
  end)
  
  events:register("keyreleased",function(key)
    local id = keymap.toCode(key)
    if id then
      events:trigger("key_up",id)
    else
      CPU.cprint("Unknown key_up: "..key)
    end
  end)

  local fw, fh = GPU.fontSize()
  local function togrid(x,y)
    return math.floor(x/(fw+1))+1, math.floor(y/(fh+2))+1
  end
  
  local mbtn
  
  events:register("mousepressed",function(x,y,btn)
    mbtn = btn
    events:trigger("mouse_click",btn,togrid(x,y))
  end)

  events:register("mousemoved",function(x,y)
    if not mbtn then return end
    if not GPU.isMDown(mbtn) then return end
    events:trigger("mouse_drag",mbtn,togrid(x,y))
  end)

  events:register("mousereleased",function(x,y,btn)
    if not mbtn then return end
    if mbtn ~= btn then return end
    mbtn = false
    events:trigger("mouse_up",btn,togrid(x,y))
  end)

  events:register("wheelmoved",function(wx,wy)
    local mx, my = togrid(GPU.getMPos())
    if wy < 0 then --Up
      events:trigger("mouse_scroll",-1,mx,my)
    elseif wy > 0 then --Down
      events:trigger("mouse_scroll",1,mx,my)
    end
  end)
  
  if CPU.isMobile() then
    events:register("touchpressed",function()
      Keyboard.textinput(true)
    end)
  end
  
end