return function() --Create new redstone API
  local rs = {}
  
  function rs.getSides()
    --return {"top", "bottom", "left", "right", "front", "back"}
    return {} --Pocket :P
  end
  
  function rs.setOutput() end --Nothing
  function rs.getOutput() return false end --Nothing
  function rs.getInput() return 0 end --Nothing
  function rs.setBundledOutput() end --Nothing
  function rs.getBundledOutput() return 0 end --Nothing
  function rs.getBundledInput() return 0 end --Nothing
  function rs.testBundledInput() return false end --Nothing
  function rs.setAnalogOutput() end --Nothing
  function rs.setAnalogueOutput() end --Nothing
  function rs.getAnalogOutput() return 0 end --Nothing
  function rs.getAnalogueOutput() return 0 end --Nothing
  function rs.getAnalogInput() return 0 end --Nothing
  function rs.getAnalogueInput() return 0 end --Nothing
  
  return rs
end