local map = {
--1
"escape", 
--2
"1", "2" , "3" , "4" , "5" , "6" , "7" , "8" , "9" , "0" , "-" , "=" , "backspace" , 
--15
"tab" , "q" , "w" , "e" , "r" , "t" , "y" , "u" , "i" , "o" , "p" , "[" , "]" , 
--28
{"return","kpenter"},
--29
"lctrl",
--30
"a" , "s" , "d" , "f" , "g" , "h" , "j" , "k" , "l" , ";" , "'",
--41
"`",
--42
"lshift",
--43
"\\",
--44
"z" , "x" , "c" , "v" , "b" , "n" , "m" , "," , "." , "/" , "rshift" ,
--55
"kp*",
--56
"lalt",
--57
"space",
--58
"capslock",
--59
"f1" , "f2" , "f3" , "f4" , "f5" , "f6" , "f7" , "f8" , "f9" , "f10",
--69
"numlock",
--70
"scrolllock",
--71
"kp7" , "kp8" , "kp9" , 
--74
"kp-",
--75
"kp4" , "kp5" , "kp6" , "kp+" , 
--79
"kp1" , "kp2" , "kp3" , 
--82
"kp0" , "kp."
--84
-- notfound
}

local map2 = {
  ["87"] = "f11",
  ["88"] = "f12",
  ["183"] = "printscreen",
  ["184"] = "ralt",
  ["219"] = "lgui",
  ["220"] = "rgui",
  ["221"] = "menu",
  ["157"] = "rctrl",
  ["181"] = "kp/",
  ["197"] = "pause",
  ["210"] = "insert",
  ["199"] = "home",
  ["201"] = "pageup",
  ["211"] = "delete",
  ["207"] = "end",
  ["209"] = "pagedown",
  ["200"] = "up",
  ["203"] = "left",
  ["208"] = "down",
  ["205"] = "right"
}

--Merge the maps
for k,v in pairs(map2) do
  map[tonumber(k)] = v
end

local fromcode = map
local tocode = {}

--Flip values and keys.
for k,v in pairs(map) do
  if type(v) == "table" then
    for k2,v2 in pairs(v) do
      tocode[v2] = k
    end
  else
    tocode[v] = k
  end
end

return {
tocode = tocode,
fromcode = fromcode,
toCode = function(key)
  return tocode[key]
end,
fromCode = function(id)
  local key = fromcode[id]
  if type(key) == "table" then
    return key[1]
  else
    return key
  end
end
}