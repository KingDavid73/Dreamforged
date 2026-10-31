local function encode(x)
 if type(x)=='number'or type(x)=='boolean'then return tostring(x)end
 if type(x)=='string'then return string.format('%q',x)end
 if type(x)~='table'then return'null'end
 local out={};for k,v in pairs(x)do out[#out+1]=encode(tostring(k))..':'..encode(v)end
 table.sort(out);return'{'..table.concat(out,',')..'}'
end
return encode
