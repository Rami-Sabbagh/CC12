return function() --Create new bit API
  local b = {}
  
  b.blshift = bit.lshift
  b.brshift = bit.rshift
  b.bxor = bit.bxor
  b.bor = bit.bor
  b.band = bit.band
  b.bnot = bit.bnot
  b.blogic_rshift = bit.arshift
  
  return b
end