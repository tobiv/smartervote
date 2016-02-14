String::hashCode = ->
  hash = 0
  i = undefined
  chr = undefined
  len = undefined
  if @length == 0
    return hash
  i = 0
  len = @length
  while i < len
    chr = @charCodeAt(i)
    hash = (hash << 5) - hash + chr
    hash |= 0
    # Convert to 32bit integer
    i++
  hash
