local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local storage=require('openmw.storage');local C,R=require('scripts.ashenloot.config'),require('scripts.ashenloot.rules')
local json=require('scripts.ashenloot_test.balance_json')
local rows={
 {name='world-early',player=1,gear=1,target=1},
 {name='world-mid',player=25,gear=25,target=25},
 {name='world-late',player=100,gear=100,target=100},
 {name='world-extreme',player=351,gear=351,target=351},
 {name='delve-early',player=1,gear=1,target=1,depth=1,density=true},
 {name='delve-mid',player=25,gear=25,target=38,depth=12,density=true},
 {name='delve-late',player=100,gear=100,target=136,depth=30,density=true},
 {name='delve-extreme',player=351,gear=351,target=387,depth=30,density=true},
 {name='depth-only',player=1,gear=1,target=37,depth=30,density=true},
 {name='personal-legacy',player=16,gear=34,target=40,depth=6},
 {name='personal-dense',player=16,gear=34,target=40,depth=6,density=true},
}
if core.contentFiles.has('rng-kernel.omwscripts')then
 local selected={};for _,r in ipairs(rows)do if r.name=='world-early'or r.name=='delve-early'or r.name=='delve-late'or r.name=='personal-legacy'or r.name=='personal-dense'then selected[#selected+1]=r end end;rows=selected
end
local row,rank,bankIndex,n,stage,t,at=1,0,1,0,0,0,0;local stats;local gearItem
local banks={0,125.9821688};local samples=10000
local function setup(p,A)
 local r=rows[row];p:sendEvent('Balance_Level',r.player)
 if gearItem and gearItem:isValid()and gearItem.count>0 then gearItem:remove()end;gearItem=nil
 if r.gear>r.player then
  local rec=world.createRecord(types.Weapon.createRecordDraft{template=types.Weapon.records['iron longsword'],name='Measurement gear'})
  A.getState().records[rec.id]={level=r.player+(r.gear-r.player)*2,tier=1}
  gearItem=world.createObject(rec.id,1);gearItem:moveInto(types.Actor.inventory(p))
 end
 stats={samples=samples,eligible=0,items=0,noEquipment=0,tiers={},multiHigh=0,spend=0}
end
return{engineHandlers={onUpdate=function(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local ok,e=pcall(function()
  local A=I.AshenLoot;local s=A.getState()
  if stage==0 and t>3 then
   storage.globalSection(C.groupKey('extraEncounters')):set('extraEncounters',false)
   storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',0)
   setup(p,A);stage=1;at=t+1
  elseif stage==1 and t>at then
   local r=rows[row];assert(A.progression.gearLevel()==r.gear,'gear profile mismatch '..r.name..' actual '..A.progression.gearLevel()..' player '..types.Actor.stats.level(p).current)
   s.delve=s.delve or {actors={},slots={}};s.delve.actors=s.delve.actors or {}
   for j=1,400 do
    n=n+1;local id=r.name..':'..rank..':'..bankIndex..':'..n..':'..R.rng('sample-key:'..n)(1000000000)
    local actor={id=id};s.director.actors[id]={level=r.target}
    if r.depth then s.delve.actors[id]={depth=r.depth,density=r.density}end
    s.elites[id]=rank>0 and {rank=math.min(3,rank),worldBoss=rank==4}or false
    local v=A.test.measurementPlan(actor,rank,id,banks[bankIndex])
    if v.eligible then stats.eligible=stats.eligible+1 end
    if #v.tiers==0 then stats.noEquipment=stats.noEquipment+1 end
    local high=0;for _,tier in ipairs(v.tiers)do stats.tiers[tier]=(stats.tiers[tier]or 0)+1;if tier>=5 then high=high+1 end end
    if high>=2 then stats.multiHigh=stats.multiHigh+1 end
    stats.items=stats.items+#v.tiers;stats.spend=stats.spend+(v.spend or 0)
    s.director.actors[id]=nil;s.delve.actors[id]=nil;s.elites[id]=nil
    if n>=samples then break end
   end
   if n>=samples then
    local r=rows[row];stats.name=r.name;stats.player=r.player;stats.gear=r.gear;stats.target=r.target;stats.depth=r.depth;stats.density=r.density;stats.rank=rank;stats.bank=banks[bankIndex]
    print('[BALANCE KERNEL] '..json(stats));n=0;rank=rank+1
    if rank>4 then rank=0;bankIndex=bankIndex+1 end
    if bankIndex>#banks then bankIndex=1;row=row+1 end
    if row>#rows then print('[BALANCE KERNEL] ALL PASS '..(#rows*10)..' conditional cohorts, '..(#rows*10*samples)..' reward-plan trials');core.quit();stage=99;return end
    setup(p,A);at=t+1
   end
  end
 end)
 if not ok then print('[BALANCE KERNEL] FAIL '..tostring(e));core.quit()end
end}}
