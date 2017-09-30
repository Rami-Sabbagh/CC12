return function() --Create new OSAPI
  local o = {}
  
  local timers = {}
  local alarms = {}
  
  --Done
  function o.queueEvent(...)
    events:trigger(...)
  end
  
  --Done
  function o.startTimer(timeout)
    table.insert(timers,math.max(timeout,0))
    return #timers
  end
  
  --Done
  function o.setAlarm(time)
    table.insert(alarms,math.max(time,0))
    return #alarms
  end
  
  --Done
  function o.shutdown()
    CPU.shutdown()
  end
  
  --Done
  function o.reboot()
    CPU.reboot()
  end
  
  --Done
  function o.computerID()
    return 0
  end
  
  --Done
  function o.getComputerID()
    return 0
  end
  
  --Done
  function o.setComputerLabel(label)
    fs.write("C:/label",label)
  end
  
  --Done
  function o.getComputerLabel()
    if fs.exists("C:/label") then
      return fs.read("C:/label")
    else
      return ""
    end
  end
  o.computerLabel = o.getComputerLabel
  
  --Done
  function o.clock()
    return os.clock()
  end
  
  --Done
  function o.time()
    local time = os.time()
    local hour = tonumber(os.date("%H",time))
    local minute = tonumber(os.date("%M",time))
    return hour + minute/60
  end
  
  --Done
  function o.day()
    return tonumber(os.date("%d",os.time()))
  end
  
  --Done
  function o.cancelTimer(id)
    if timers[id] then
      timers[id] = -1
    end
  end
  
  --Done
  function o.cancelAlarm(id)
    if alarms[id] then
      alarm[id] = -1
    end
  end
  
  --Done
  function o.epoch()
    local time = os.time()
    local hour = tonumber(os.date("%H",time))
    local minute = tonumber(os.date("%M",time))
    return hour + minute/60
  end
  
  local lasttime = o.time()
  events:register("update",function(dt)
    for k,timer in ipairs(timers) do
      if timer >= 0 then
        timers[k] = timers[k] - dt
        if timers[k] < 0 then
          events:trigger("timer",k)
        end
      end
    end
    
    local curtime = o.time()
    local delta
    if curtime > lasttime then
      delta = curtime - lasttime
    else
      delta = 24 - lasttime + curtime
    end
    lasttime = curtime
    
    for k,alarm in ipairs(alarms) do
      if alarm >= 0 then
        alarms[k] = alarms[k] - delta
        if alarms[k] < 0 then
          events:trigger("alarm",k)
        end
      end
    end
  end)
  
  return o
end