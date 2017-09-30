return function() --Create new FS API
  local fs = {}
  
  local function fixPath(path)
    if path:sub(1,1) ~= "/" then
      path = "/"..path
    end
    return "D:"..path
  end
  
  --A usefull split function
  local function split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      t[i] = str
      i = i + 1
    end
    return t
  end
  
  local function lastIndexOf(str,of)
    local lastIndex = 0
    local lastEnd = 0
    while true do
      local cstart,cend = string.find(str,of,lastEnd+1)
      if cstart then
        lastIndex, lastEnd = cstart, cend
      else
        break
      end
    end
    
    return lastIndex
  end
  
  local function indexOf(str,of)
    local cstart,cend = string.find(str,of)
    if cstart then return cstart else return 0 end
  end
  
  local function sanitizePath(path,wild)
    --Allow windowsy slashes
    path = path:gsub("\\","/")
    
    --Clean the path or illegal characters.
    local specialChars = {
      "\"", ":", "<", ">", "%?", "|" --Sorted by ascii value (important)
    }
    
    if not wild then table.insert(specialChars,"%*") end
    
    for k, char in ipairs(specialChars) do
      path = path:gsub(char,"")
    end
    
    --Collapse the string into its component parts, removing ..'s
    local parts = split(path,"/")
    local output = {}
    for k, part in ipairs(parts) do
      if part:len() > 0 and part ~= "." then
        
        if part == ".." or part == "..." then
          --.. or ... can cancel out the last folder entered
          if #output > 0 and output[#output] ~= ".." then
            output[#output] = nil
          else
            table.insert(output,"..")
          end
        elseif part:len() > 255 then
          --If part length > 255 and it is the last part
          table.insert(output,part:sub(1,255))
        else
          --Antyhing else we add to the stack
          table.insert(output,part)
        end
        
      end
    end
    
    --Recombine the output parts into a new string
    return table.concat(output,"/")
  end
  
  local function findIn( startDir, matches, wildPattern )
    local list = fs.directoryItems(startDir)
    for k, entry in ipairs(list) do
      local entryPath = (startDir:len() == 0) and entry or startDir.."/"..entry
      if string.match(entryPath, wildPattern) then
        table.insert(matches,entryPath)
      end
      
      if fs.isDirectory( entryPath) then
        findIn( entryPath, matches, wildPattern )
      end
    end
  end
  
  --Done
  function fs.list(path)
    path = sanitizePath(path)
    return HDD.directoryItems(path)
  end
  
  --Done
  function fs.combine(path, childPath)
    path = sanitizePath(path,true)
    childPath = sanitizePath(childPath,true)
    
    if path:len() == 0 then
      return childPath
    elseif childPath:len() == 0 then
      return path
    else
      return sanitizePath( path.."/"..childPath, true )
    end
  end
  
  --Done
  function fs.getName(path)
    path = sanitizePath(path,true)
    if path:len() == 0 then
      return "root"
    end
    
    local lastSlash = lastIndexOf(path,"/")
    if lastSlash > 0 then
      return path:sub(lastSlash+1,-1)
    else
      return path
    end
  end
  
  --Done
  function fs.getSize(path)
    path = sanitizePath(path)
    return HDD.getSize(path)
  end
  
  --Done
  function fs.exists(path)
    path = sanitizePath(path)
    return HDD.exists(path)
  end
  
  --Done
  function fs.isDir(path)
    path = sanitizePath(path)
    if not HDD.exists(path) then return false end
    return HDD.isDirectory(path)
  end
  
  --Done
  function fs.isReadOnly(path)
    path = sanitizePath(path)
    if path:sub(1,3) == "rom" then return true end
    return false
  end
  
  --Done
  function fs.makeDir(path)
    path = sanitizePath(path)
    HDD.newDirectory(path)
  end
  
  --Done
  function fs.move(from,to)
    from = sanitizePath(from)
    to = sanitizePath(to)
    
    fs.copy(from,to)
    fs.delete(from,to)
  end
  
  local function copyRecursive(from, to)
    if not HDD.exists(from) then return end
    
    if HDD.isDirectory(from) then
      --Copy a directory:
      --Make the new directory
      HDD.newDirectory(to)
      
      --Copy the source contents into it
      local files = HDD.directoryItems(from)
      for k,file in ipairs(files) do
        copyRecursive(
          fs.combine(from,file),
          fs.combine(to,file)
        )
      end
    else
      --Copy a file
      local data = HDD.read(from)
      HDD.write(to,data)
    end
  end
  
  --Done
  function fs.copy(from,to)
    from = sanitizePath(from)
    to = sanitizePath(to)
    
    copyRecursive(from,to)
  end
  
  local function deleteRecursive(path)
    if not HDD.exists(path) then return end
    
    if HDD.isDirectory(path) then
      --Delete a directory:
      
      local files = HDD.directoryItems(path)
      for k,file in ipairs(files) do
        deleteRecursive(fs.combine(path,file))
      end
      
      HDD.remove(path) --Delete the directory
    else
      --Delete a file
      
      HDD.remove(path)
    end
  end
  
  --Done
  function fs.delete(path)
    path = sanitizePath(path)
    deleteRecursive(path)
  end
  
  --Done
  function fs.open(path,mode)
    path = sanitizePath(path)
    
    local file = {}
    function file.close() end --nothing :P
    
    local data = ""
    if mode == "r" or mode == "rb" then
      data = HDD.read(path)
    end
    
    if mode == "r" then
      data = data:gsub("\r","")
      local iterdata = data
      if iterdata:sub(-1,-1) ~= "\n" then
        iterdata = iterdata.."\n"
      end
      file.readLine = string.gmatch(data,"(.-)\n")
      
      if data:sub(-1,-1) == "\n" then
        data = data:sub(1,-2)
      end
      
      function file.readAll()
        return data
      end
    elseif mode == "rb" then
      local iter = string.gmatch(data,".")
      return function()
        local char = iter()
        if char then
          return string.byte(char)
        end
      end
    end
    
    if mode == "w" or mode == "a" then
      function file.write(d)
        data = data..d
      end
      
      function file.writeLine(d)
        data = data..d.."\n"
      end
    elseif mode == "wb" or mode == "ab" then
      function file.write(d)
        data = data .. string.char(d)
      end
    end
    
    if mode == "w" or mode == "wb" then
      function file.flush()
        HDD.write(path,data)
      end
      file.close = file.flush
    elseif mode == "a" or mode == "ab" then
      function file.flush()
        HDD.append(path,data)
        data = ""
      end
      file.close = file.flush
    end
    
    return file
  end
  
  --Done
  function fs.getDrive(path)
    if fs.isReadOnly(path) then return "rom" else
      return "hdd1"
    end
  end
  
  --Done
  function fs.getFreeSpace()
    local drives = HDD.drives()
    local drive = HDD.drive()
    return drives[drive].size - drives[drive].usage
  end
  
  local function recurse_spec(results, path, spec)
    local segment = spec:match('([^/]*)'):gsub('/', '')
    local pattern = '^' .. segment:gsub("[%.%[%]%(%)%%%+%-%?%^%$]","%%%1"):gsub("%z","%%z"):gsub("%*","[^/]-") .. '$'

    if fs.isDir(path) then
      for _, file in ipairs(fs.list(path)) do
        if file:match(pattern) then
          local f = fs.combine(path, file)

          if spec == segment then
            table.insert(results, f)
          end
          if fs.isDir(f) then
            recurse_spec(results, f, spec:sub(#segment + 2))
          end
        end
      end
    end
  end
  
  --Done
  function fs.find(wildPath)
    local wildPath = sanitizePath(wildPath, true)
    local results = {}
    recurse_spec(results,'',wildPath)
    return results
  end
  
  --DAN200 Version
  --[[
  function fs.find(wildPath)
    CPU.cprint("[FSAPI]: find -> "..wildPath)
    --Match all the files on the system
    wildPath = sanitizePath(wildPath, true)
    
    --If we don't ave a wildcard at all just check the file exists
    local starIndex = indexOf(wildPath,"%*")
    if starIndex < 1 then
      return HDD.exists(wildPath) and {wildPath} or {}
    end
    
    --Find the all non-wildcarded directories. For instance foo/bar/baz* -> foo/bar
    local prevDir = lastIndexOf(wildPath:sub(1,starIndex),"/")
    local startDir = (prevDir < 1) and "" or wildPath:sub(1,prevDir)
    
    --If this isn't a directory then just abort
    if not HDD.isDirectory(startDir) then return {} end
    
    --Scan as normal, starting from this directory
    local wildPattern = "^\"" .. string.gsub(wildPath,"\\*","\"[^/]*\"") .. "\"$"
    local matches = {}
    findIn(startDir, matches, wildPattern)
    
    return matches
  end
  ]]
  
  --Done
  function fs.getDir(path)
    path = sanitizePath(path)
    if path:len() == 0 then return ".." end
    
    local lastSlash = lastIndexOf(path,"/")
    if lastSlash > 0 then
      return path:sub(1,lastSlash)
    else
      return ""
    end
  end
  
  return fs
end