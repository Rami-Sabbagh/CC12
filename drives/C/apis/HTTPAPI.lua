return function() --Create new HTTP peripheral
  local h = {}
  
  --Done
  function h.request(url, postdata, headers)
    local args = {}
    
    if postdata then args.method = "POST" end
    args.headers = headers
    args.data = postdata
    
    WEB.send(url,args)
    
    return true
  end
  
  --Done
  function h.checkURL()
    return true --This has to be changed later :/
  end
  
  events:register("webrequest", function(id,url,out,errorcode,errorstr,errline)
    CPU.cprint("Webrequest: ",id,url,out,errorcode,errorstr,errline)
    if out then
      local hl = {}
      function hl.close() end --Nothing
      
      local data = out.body
      
      data = data:gsub("\r","")
      local iterdata = data
      if iterdata:sub(-1,-1) ~= "\n" then
        iterdata = iterdata.."\n"
      end
      h.readLine = string.gmatch(data,"(.-)\n")
      
      if data:sub(-1,-1) == "\n" then
        data = data:sub(1,-2)
      end
      
      function hl.readAll()
        return data
      end
      
      function hl.getResponseCode()
        return out.code
      end
      
      events:trigger("http_success",url,hl)
    else
      events:trigger("http_failure",url)
    end
  end)
  
  return h
end