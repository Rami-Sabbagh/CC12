return function() --Create new terminal API
  local function getHighestBit( group )
    local b = 0
    while group > 0 do
      group = bit.rshift(group,1)
      b = b + 1
    end
    return b
  end
  
  local function parseColor(color)
    if type(color) ~= "number" then error("Color must be a number, provided: "..type(color),2) end
    if color <= 0 then return error("Color out of range") end
    color = getHighestBit(color) -1
    if color < 0 or color > 15 then return error("Color out of range") end
    return color
  end
  
  local function encodeColor(color)
    return bit.lshift(1,color)
  end
  
  local function decodeRGB8(rgb)
    local r = bit.band(bit.rshift(rgb,16),0xFF)/255
    local g = bit.band(bit.rshift(rgb,8),0xFF)/255
    local b = bit.band(rgb,0xFF)/255
    return r,g,b
  end
  
  local function encodeRGB8(r,g,b)
    local r = bit.band(math.floor(r*255),0xFF)
    local g = bit.band(math.floor(g*255),0xFF)
    local b = bit.band(math.floor(b*255),0xFF)
    local rg = bit.bor(bit.lshift(r,16),bit.lshift(g,8))
    return bit.bor(rg,b)
  end
  
  ----------------------------------------------------------------
  
  local base16 = "0123456789abcdef"

  local m_cursorX, m_cursorY = 0,0 --int
  local cursorBlink = false --boolean
  local cursorColor = 0 --int
  local cursorBackgroundColor = 15 --int

  --local m_width, m_height = termSize() --int

  local m_text = {} --TextBuffer
  local m_textColor = {} --TextBuffer
  local m_backgroundColor = {} --TextBuffer

  local palette = {} --Palette
  for i=0,15 do
    local r,g,b = GPU.colorPalette(i)
    palette[i] = encodeRGB8(r/100,g/100,b/100)
  end

  local m_changed = false --boolean
  
  ----------------------------------------------------------------
  
  local tw, th = GPU.termSize()
  local fw, fh = GPU.fontSize()
  
  local btime = 0.5
  local btimer = 0
  local bflag = false
  local bsc, bsc_x, bsc_y
  
  local function idraw()
    if bsc then
      GPU.pushPalette()
      GPU.pal()
      bsc:draw(bsc_x,bsc_y)
      bsc = nil
      GPU.popPalette()
    end
  end
  
  local term = {}
  
  --Done
  function term.write(text)
    idraw()
    local txt = ""
    if type(text) ~= "nil" then txt = tostring(text) end
    GPU.print(text,false)
    GPU.flip()
  end
  
  --Done
  function term.scroll(y)
    idraw()
    GPU.print(string.rep("\n",y-1))
    GPU.flip()
  end
  
  --Done
  function term.setCursorPos(x,y)
    idraw()
    if type(x) ~= "number" then return error("X must be a number") end
    if type(y) ~= "number" then return error("Y must be a number") end
    GPU.printCursor(x-1,y-1)
    if cursorBlink then GPU.flip() end
  end
  
  --Done
  function term.setCursorBlink(bool)
    idraw()
    if bool then
      cursorBlink = true
    else
      cursorBlink = false
    end
    GPU.flip()
  end
  
  --Done
  function term.getCursorPos()
    local x,y = GPU.printCursor()
    return x+1, y+1
  end
  
  --Done
  function term.getSize()
    return GPU.termSize()
  end
  
  --Done
  function term.clear()
    idraw()
    GPU.clear(15)
    GPU.rect(0,0,tw*(fw+1),th*(fh+1),false,cursorColor)
    GPU.flip()
  end
  
  --Done
  function term.clearLine()
    idraw()
    local cx,cy,cc = GPU.printCursor()
    GPU.printCursor(0,cy,cc)
    GPU.print(string.rep(" ",GPU.termWidth()),false,true)
    GPU.printCursor(cx,cy,cc)
    GPU.flip()
  end
  
  --Done
  function term.setTextColor(c)
    local col = parseColor(c)
    GPU.color(col)
  end
  term.setTextColour = term.setTextColor
  
  --Done
  function term.setBackgroundColor(c)
    local col = parseColor(c)
    GPU.printCursor(false,false,col)
  end
  term.setBackgroundColour = term.setBackgroundColor
  
  --Done :P
  function term.isColor()
    return true
  end
  term.isColour = term.isColor
  
  --Done
  function term.getTextColor()
    return encodeColor(GPU.color())
  end
  term.getTextColour = term.getTextColor
  
  --Done
  function term.getBackgroundColor()
    local cx,cy,cc = GPU.printCursor()
    return encodeColor(cc)
  end
  term.getBackgroundColour = term.getBackgroundColor
  
  --Done
  function term.blit(text,textColor,textBackgroundColor)
    idraw()
    if textColor:len() ~= text:len() or textBackgroundColor:len() ~= text:len() then
      return error("Arguments must be the same length")
    end
    
    GPU.pushColor()
    local cx,cy,cc = GPU.printCursor()
    for i=1,text:len() do
      local char = text:sub(i,i)
      local col = textColor:sub(i,i)
      local bgcol = textBackgroundColor:sub(i,i)
      GPU.color(tonumber(col,16))
      GPU.printCursor(false,false,tonumber(bgcol,16))
      GPU.print(char,false)
    end
    GPU.printCursor(false,false,cc)
    GPU.popColor()
    GPU.flip()
  end
  
  --Done
  function term.setPaletteColor(id,r,g,b)
    local col = parseColor(id)
    if g then
      palette[col] = encodeRGB8(r,g,b)
    else
      palette[col] = r
    end
  end
  term.setPaletteColour = term.setPaletteColor
  
  --Done
  function term.getPaletteColor(id)
    local col = parseColor(id)
    return decodeRGB8(palette[col])
  end
  term.getPaletteColour = term.getPaletteColor
  
  events:register("update",function(dt)
    if cursorBlink then
      btimer = btimer + dt
      if btimer > btime then
        idraw()
        bflag = not bflag
        if bflag then
          local cx,cy = GPU.printCursor()
          local fw,fh = GPU.fontSize()
          local x,y = cx*(fw+1)+1, cy*(fh+1)+1
          bsc = GPU.screenshot(x,y,fw+2,fh-1):image()
          bsc_x, bsc_y = x,y
          GPU.rect(x,y,fw+1,fh-1,false,12)
        end
        btimer = btimer % btime
      end
    end
  end)
  
  return term
end