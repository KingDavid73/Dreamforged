-- Versioned gameplay streams. MurmurHash3 x86_32: Austin Appleby, public domain.
-- Reference: https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp
-- Arithmetic shifts and split 16-bit products avoid signed-bit and double rounding differences.
local xor=require('openmw.util').bitXor
local M={version=1};local U32=4294967296
local function bxor(a,b)return xor(a,b)%U32 end
local function mul(a,b)
    local lo=a%65536;local hi=math.floor(a/65536)
    return (lo*(b%65536)+((hi*(b%65536)+lo*math.floor(b/65536))%65536)*65536)%U32
end
local function rot(x,n)return (x*2^n)%U32+math.floor(x/2^(32-n))end
function M.hash(text,seed)
    local h=(seed or 0)%U32;local length=#text;local tail=length-length%4
    for i=1,tail,4 do
        local a,b,c,d=text:byte(i,i+3);local k=a+b*256+c*65536+d*16777216
        k=mul(rot(mul(k,0xcc9e2d51),15),0x1b873593)
        h=(mul(rot(bxor(h,k),13),5)+0xe6546b64)%U32
    end
    local k=0
    for i=tail+1,length do k=k+text:byte(i)*256^(i-tail-1)end
    if length>tail then h=bxor(h,mul(rot(mul(k,0xcc9e2d51),15),0x1b873593))end
    h=bxor(h,length);h=mul(bxor(h,math.floor(h/65536)),0x85ebca6b)
    h=mul(bxor(h,math.floor(h/8192)),0xc2b2ae35)
    return bxor(h,math.floor(h/65536))
end
function M.new(seed,namespace)
    assert(type(namespace)=='string'and #namespace>0,'RNG stream requires a namespace')
    seed=tostring(seed)
    local key='dreamforged-stream-v1:'..#namespace..':'..namespace..#seed..':'..seed
    local n=1+M.hash(key)%2147483646
    return function(max)
        n=(n*48271)%2147483647
        local v=n/2147483647
        return max and math.floor(v*max)+1 or v
    end
end
return M
