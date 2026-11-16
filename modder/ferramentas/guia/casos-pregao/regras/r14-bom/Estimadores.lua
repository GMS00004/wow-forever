local _, ns = ...
function ns.media(a, b)
  return (a + b) / 2
end
function ns.texto(n)
  return string.format("%d", math.floor(n))
end
