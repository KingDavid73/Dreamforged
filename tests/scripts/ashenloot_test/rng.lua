local core=require('openmw.core');local R=require('scripts.ashenloot.rules');local Stream=require('scripts.ashenloot.random_stream')
local json=require('scripts.ashenloot_test.balance_json');local done=false
local namespaces={'density-reward-v1','equipment-gate-v1','promotion-gate-v1','promotion-boss-v1','promotion-unique-v1','promotion-elite-v1','promotion-modifiers-v1','supplies-v1','spell-tome-v1','loot-budget-v1','delve-species-v1','delve-placement-v1','elite-base-v1'}
local function check(v,s)assert(v,s);print('[RNG FIX] PASS '..s)end
local function close(count,expected,n,label)
 local tolerance=math.max(12,7*math.sqrt(math.max(1,n*expected*(1-expected))))
 assert(math.abs(count-n*expected)<tolerance,label..' count '..count..' expected '..n*expected..' tolerance '..tolerance)
end
local function legacy(seed)
 local n=1;for i=1,#seed do n=(n*31+seed:byte(i))%2147483647 end
 return function(max)n=n*48271%2147483647;local v=n/2147483647;return max and math.floor(v*max)+1 or v end
end
local function run()
 local vectors=require('scripts.ashenloot_test.rng_vectors')
 for _,v in ipairs(vectors)do assert(Stream.hash(v.text,v.seed)==v.hash,'hash vector mismatch '..v.text..' seed '..v.seed)end
 check(true,#vectors..' exact independent integer hash vectors, including boundaries and UTF8')
 for _,v in ipairs(vectors.streams)do
  local a,b=R.stream(v.seed,v.namespace),R.stream(v.seed,v.namespace)
  for _,expected in ipairs(v.draws)do assert(math.abs(a()-expected)<1e-15,'framed stream vector mismatch');assert(b(100)==math.floor(expected*100)+1,'bounded stream vector mismatch')end
 end
 check(true,'independent framed stream vectors and integer bounds')
 for _,seed in ipairs({'','actor','0x1234','éΩ猫'})do
  local old,actual=legacy(seed),R.rng(seed);for i=1,100 do assert(old()==actual(),'legacy RNG changed')end
  for _,ns in ipairs(namespaces)do
   local a,b=R.stream(seed,ns),R.stream(seed,ns)
   for i=1,100 do local x=a();assert(x==b()and x>0 and x<1,'stream repeat/range failure')end
  end
 end
 check(R.stream('bc','a')()~=R.stream('c','ab')(),'length framing separates ambiguous seed/namespace pairs')
 local frameVectors={};for _,ns in ipairs(namespaces)do frameVectors[ns]=R.stream('0x00001234',ns)()end
 print('[RNG GOLDEN] '..json(frameVectors))
 for _,pattern in ipairs({'consecutive','strided','decimal'})do
  local n=100000;local gate,equipment,joint,pg,unique,pj,boss,bj=0,0,0,0,0,0,0,0
  local aSum,bSum,aa,bb,ab,previous,lag=0,0,0,0,0,nil,0
  local histogram={};for i=1,10 do histogram[i]=0 end
  for i=1,n do
   local id=pattern=='decimal'and tostring(i)or '0x'..string.format('%08x',pattern=='consecutive'and i or i*7919)
   local a=R.stream(id,'density-reward-v1')();local b=R.stream(id,'equipment-gate-v1')()
   local p=R.stream(id,'promotion-gate-v1')();local u=R.stream(id,'promotion-unique-v1')(100)
   local bo=R.stream(id,'promotion-boss-v1')(100)
   if a<1/6 then gate=gate+1 end;if math.floor(b*100)+1<=12.4 then equipment=equipment+1 end
   if a<1/6 and math.floor(b*100)+1<=12.4 then joint=joint+1 end
   if p<.08 then pg=pg+1 end;if u<=5 then unique=unique+1 end
   if p<.08 and u<=5 then pj=pj+1 end
   if bo<=3 then boss=boss+1 end;if p<.08 and bo<=3 then bj=bj+1 end
   aSum=aSum+a;bSum=bSum+b;aa=aa+a*a;bb=bb+b*b;ab=ab+a*b
   histogram[math.floor(a*10)+1]=histogram[math.floor(a*10)+1]+1
   if previous then lag=lag+previous*a end;previous=a
  end
  close(gate,1/6,n,'density marginal');close(equipment,.12,n,'equipment marginal');close(joint,.12/6,n,'density/equipment intersection')
  close(pg,.08,n,'promotion marginal');close(unique,.05,n,'unique marginal');close(pj,.08*.05,n,'promotion/unique intersection')
  close(boss,.03,n,'boss marginal');close(bj,.08*.03,n,'promotion/boss intersection')
  for _,count in ipairs(histogram)do close(count,.1,n,'consecutive-ID histogram')end
  local correlation=(ab-aSum*bSum/n)/math.sqrt((aa-aSum*aSum/n)*(bb-bSum*bSum/n))
  local lagCorrelation=(lag/(n-1)-(aSum/n)^2)/(aa/n-(aSum/n)^2)
  check(math.abs(correlation)<.02 and math.abs(lagCorrelation)<.02,'cross-stream and ID-neighbour correlations '..pattern)
  print('[RNG DISTRIBUTION] '..json({pattern=pattern,n=n,density=gate,equipment=equipment,joint=joint,promotion=pg,unique=unique,promotedUnique=pj,boss=boss,promotedBoss=bj,correlation=correlation,lagCorrelation=lagCorrelation}))
 end
 for _,ns in ipairs(namespaces)do
  local n=50000;local hits=0;local bins={};for j=1,10 do bins[j]=0 end
  for i=1,n do local x=R.stream('0x'..string.format('%08x',i),ns)();hits=hits+(x<.25 and 1 or 0);bins[math.floor(x*10)+1]=bins[math.floor(x*10)+1]+1 end
  close(hits,.25,n,'stream marginal '..ns);for _,count in ipairs(bins)do close(count,.1,n,'stream bins '..ns)end
 end
 check(true,'all 13 opted-in gameplay namespaces pass consecutive-ID marginals')
 check(true,'legacy output unchanged, new streams deterministic and bounded')
 print('[RNG FIX] ALL PASS deterministic vectors, marginal/joint distributions and neighbouring IDs');core.quit()
end
return{engineHandlers={onUpdate=function()if done then return end;done=true;local ok,e=pcall(run);if not ok then print('[RNG FIX] FAIL '..tostring(e));core.quit()end end}}
