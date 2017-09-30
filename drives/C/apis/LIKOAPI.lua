return function() --Create new LIKO12 API
  local liko = {}
  
  for k,v in pairs(GPU) do
    liko[k] = v
  end
  
  for k,v in pairs(CPU) do
    liko[k] = v
  end
  
  for k,v in pairs(Keyboard) do
    liko[k] = v
  end
  
  liko.fs = HDD
  
  return liko
end