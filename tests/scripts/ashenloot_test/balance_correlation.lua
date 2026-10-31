local core=require('openmw.core');local R=require('scripts.ashenloot.rules');local json=require('scripts.ashenloot_test.balance_json')
local done=false
return{engineHandlers={onUpdate=function()
 if done then return end;done=true
 for _,chance in ipairs({12.4,18.25,22.25})do
  local s={n=100000,chance=chance,gate=0,equipment=0,joint=0,controlJoint=0,offsetError=0}
  local offset=(R.rng(':loot-budget-v1')()-R.rng(':density-reward')())%1
  for n=1,s.n do
   local id='0x'..string.format('%08x',n*7919)
   local gate=R.rng(id..':density-reward')();local loot=R.rng(id..':loot-budget-v1')
   local roll=loot(100);if gate<1/6 then s.gate=s.gate+1 end
   if roll<=chance then s.equipment=s.equipment+1 end
   if gate<1/6 and roll<=chance then s.joint=s.joint+1 end
   for i=1,5 do loot()end
   if gate<1/6 and loot(100)<=chance then s.controlJoint=s.controlJoint+1 end
   local raw=R.rng(id..':loot-budget-v1')()
   s.offsetError=math.max(s.offsetError,math.abs(((gate+offset)%1)-raw))
  end
  s.expectedIndependent=s.gate*s.equipment/s.n
  print('[BALANCE CORRELATION] '..json(s))
  assert(s.offsetError<1e-10,'same-length suffix affine-offset proof failed')
 end
 for _,gateChance in ipairs({.08,.1625,.5})do
  local s={kind='promotion-unique',n=100000,gateChance=gateChance,gate=0,unique=0,joint=0,offsetError=0}
  local offset=(R.rng(':rank4')()-R.rng(':elite')())%1
  for n=1,s.n do
   local id='0x'..string.format('%08x',n*7919)
   local gate=R.rng(id..':elite')();local tier=R.rng(id..':rank4')(100)
   if gate<gateChance then s.gate=s.gate+1 end
   if tier<=5 then s.unique=s.unique+1 end
   if gate<gateChance and tier<=5 then s.joint=s.joint+1 end
   s.offsetError=math.max(s.offsetError,math.abs(((gate+offset)%1)-R.rng(id..':rank4')()))
  end
  s.expectedIndependent=s.gate*s.unique/s.n
  print('[BALANCE CORRELATION] '..json(s))
  assert(s.offsetError<1e-10,'promotion/first-rank-roll affine proof failed')
 end
 print('[BALANCE CORRELATION] ALL PASS actual RNG verifies gate/first-loot-roll coupling; burn control is diagnostic only');core.quit()
end}}
