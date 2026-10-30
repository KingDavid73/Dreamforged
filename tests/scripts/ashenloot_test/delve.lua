local core,world,types,I=require('openmw.core'),require('openmw.world'),require('openmw.types'),require('openmw.interfaces')
local util=require('openmw.util')
local stage,time,collision,loaded=0,0,nil,false
local function check(v,s) assert(v,s);print('[DELVE TEST] PASS '..s) end
local function run(dt)
 time=time+dt;local p=world.players[1];if not p then return end
 local api=I.AshenLoot;if not api then return end
 local D=api.delve;local s=api.getState();local d=D.test.data()
 if stage==0 and time>3 then
  check(types.Player.quests(p)['df_unending_dream'].stage>=20,'shrine grants quest entry')
  check(d.portalSpell and types.Actor.spells(p)[d.portalSpell],'portal spell learned')
  check(core.magic.spells.records[d.portalSpell].alwaysSucceedFlag,'portal bypasses skill checks')
  D.test.shop(p);check(#d.offers==3,'broker generates three offers')
  s.forgePoints[p.id]={0,0,20,20,20,0}
  p:teleport(p.cell,util.vector3(850,150,8),{onGround=true});stage=1
 elseif stage==1 and time>5 then
  for _,o in ipairs(d.offers) do check(o.item and o.item.type.record(o.item).value==0,'broker equipment has zero gold value') end
  local o=d.offers[1];local before=s.forgePoints[p.id][o.tier]
  D.action{player=p,action='buy',index=1,epoch=d.offeredEpoch}
  check(o.sold,'broker accepts purchased offer')
  check(s.forgePoints[p.id][o.tier]==before-8,'purchase debits exact coin price')
  D.action{player=p,action='buy',index=1,epoch=d.offeredEpoch}
  check(s.forgePoints[p.id][o.tier]==before-8,'duplicate purchase cannot spend twice')
  D.test.descend(p);stage=2
 elseif stage==2 and time>8 then
  check(d.offers[1].item.parentContainer==p,'broker transfers purchased offer')
  check(p.cell.name=='Dreamforged Depth 01' and d.depth==1,'first generated floor loads')
  check(collision,'generated mesh has physical floor collision')
  local slot=d.slots[1];check(#slot.objects==4,'initial population is bounded')
  D.test.retreat(p);stage=3
 elseif stage==3 and time>10 then
  check(p.cell.name=='Seyda Neen, Shrine of the Unending Dream','portal reaches shrine')
  local stock=d.offers;D.test.shop(p);check(stock==d.offers,'portal return does not reroll stock')
  D.test.resume(p);stage=4
 elseif stage==4 and time>12 then
  check(p.cell.name=='Dreamforged Depth 01' and #d.slots[1].objects==4,'resume preserves floor population')
  D.test.descend(p);stage=5
 elseif stage==5 and time>15 then D.test.descend(p);stage=6
 elseif stage==6 and time>18 then
  check(d.depth==3 and d.slots[3].boss,'third floor has guaranteed boss')
  local boss=d.slots[3].boss
  check(s.elites[boss.id] and s.elites[boss.id].worldBoss,'third-floor guardian uses real World Boss promotion')
  boss:addScript('scripts/ashenloot_test/delve_actor.lua');boss:sendEvent('DelveTest_Kill')
  stage=7
 elseif stage==7 and time>21 then
  check(d.bosses==1 and d.slots[3].bossDefeated,'boss victory recorded once')
  D.test.retreat(p);stage=8
 elseif stage==8 and time>23 then
  D.test.shop(p);check(d.offeredEpoch==1 and not d.offers[1].sold,'boss victory refreshes shop')
  -- Exercise actual cast effect detection, not merely the portal button helper.
  D.test.resume(p);stage=9
 elseif stage==9 and time>25 then
  types.Actor.activeSpells(p):add{id=d.portalSpell,effects={0},caster=p}
  stage=10
 elseif stage==10 and time>28 then
  check(p.cell.name=='Seyda Neen, Shrine of the Unending Dream','casting Dream Portal effect triggers travel')
  types.Player.sendMenuEvent(p,'AshenLoot_TestSave');stage=11
 elseif stage==11 and loaded then
  check(d.depth==3 and d.bosses==1 and d.offeredEpoch==1,'save/load preserves run and broker epoch')
  D.test.resume(p);stage=12
 elseif stage==12 and time>31 then
  check(d.slots[3].bossDefeated,'save/load does not resurrect boss');D.test.descend(p);stage=13
 elseif stage==13 and time>34 then
  check(p.cell.name=='Dreamforged Depth 04','palette switches after three depths')
  stage=14
 elseif stage>=14 and stage<=22 and time>34+(stage-13)*3 then
  check(d.depth==stage-10,'depth advances through theme cycle')
  D.test.descend(p);stage=stage+1
 elseif stage==23 and time>65 then
  check(d.depth==13 and p.cell.name=='Dreamforged Depth 01','endless descent recycles a layout at depth 13')
  check(d.slots[1].depth==13 and #d.slots[1].objects==4,'recycled layout has fresh bounded population')
  print('[DELVE TEST] ALL PASS');core.quit()
 elseif time>90 then error('test timed out at stage '..stage) end
end
return {engineHandlers={onUpdate=function(dt)local ok,err=pcall(run,dt);if not ok then print('[DELVE TEST] FAIL '..tostring(err));core.quit() end end,
 onSave=function()return {stage=stage,time=time,collision=collision}end,
 onLoad=function(d)stage,time,collision=d.stage,d.time,d.collision;loaded=true end},
 eventHandlers={DelveTest_Collision=function(e)collision=e.hit end}}
