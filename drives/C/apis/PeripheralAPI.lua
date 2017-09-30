return function() --Create new peripheral api
  local p = {}
  
  function p.isPresent() return false end --Nothing
  function p.getType() end --Nothing
  function p.getMethods() end --Nothing
  function p.call() return error("No peripheral attached") end --Simple
  
  return p
end