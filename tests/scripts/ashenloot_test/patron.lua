local core,world,I,types=require('openmw.core'),require('openmw.world'),require('openmw.interfaces'),require('openmw.types')
local storage,util=require('openmw.storage'),require('openmw.util')
local N,C=require('scripts.ashenloot.narration'),require('scripts.ashenloot.config')
local layouts=require('scripts.ashenloot.delve_layouts')
local t,stage,at,loaded=0,0,0,false;local heard,report={},nil;local before,bossText
local function check(v,s)assert(v,s);print('[PATRON] PASS '..s)end
local function run(dt)
 t=t+dt;local p=world.players[1];if not p or not I.AshenLoot then return end
 local A=I.AshenLoot;local D=A.delve;local state=A.getState();local now=core.getSimulationTime()
 if stage==0 and t>3 then
  for kind in pairs(N.patronLines)do
   local line=N.render(kind,'fixture',{enemy='Challenger',tier='Elite',item='Test Relic',depth=3},nil,'delve')
   check(line.speaker=='Fa-Nuit-Hen' and not line.text:find('{',1,true) and not line.text:find('Dagoth',1,true),'patron pool '..kind)
  end
  check(N.render('boss','fixture',{enemy='Rat'}).speaker=='Dagoth Ur','ordinary-world rendering remains Dagoth Ur')
  local fixture={};N.offerDungeon(fixture,'entry','descent',{},now,3);N.offerDungeon(fixture,'guardian','guardian',{},now,4);N.offerDungeon(fixture,nil,'peak',{},now,1)
  check(fixture.voice.pending.kind=='guardian','guardian cue wins over routine chatter')
  local special;local listener={cell={isExterior=true,id='fixture'},isValid=function()return true end,sendEvent=function(_,_,e)special=e end}
  check(N.emitSpecial({voice={patronAt=1}},{enabled=true,directorVoiceFrequency=100},listener,now,{name='Test Prince',line='Original special line'})and special.speaker=='Test Prince','world special voice survives patron-only saved state')
  check(not N.emitPressure({},C,p,now,100,3),'refuge blocks wilderness pressure captions')
  storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',100)
  state.director.outdoor.pressure=100;state.director.outdoor.pressureVoiceStage=0
  D.test.descend(p);stage=1;at=t+6
 elseif stage==1 and t>at then
  check(#heard>0 and heard[1].speaker=='Fa-Nuit-Hen','actual descent uses patron')
  check(state.director.outdoor.pressureVoiceStage==0,'outdoor pressure polling does not consume milestones indoors')
  p:sendEvent('Patron_Report',{});stage=2;at=t+1
 elseif stage==2 and t>at then
  check(report and report.visible and report.message.speaker=='Fa-Nuit-Hen','actual caption card shows patron')
  local slot=D.test.data().slots[1];slot.voice.pending=nil;state.voice.patronAt=now-20
  check(N.emitChance(state,C,p,now,'mythicPrize',{item='Test Relic',sourceCell=p.cell.id},100),'dungeon reward event emits')
  check(not N.emitChance(state,C,p,now+1,'promotion',{enemy='Rat'},100),'patron cooldown prevents stacked captions')
  check(not N.emitChance(state,C,p,now+20,'promotion',{sourceCell='wrong-cell'},100),'remote actor message rejected')
  stage=3;at=t+2
 elseif stage==3 and t>at then
  check(heard[#heard].speaker=='Fa-Nuit-Hen' and heard[#heard].text:find('Test Relic',1,true),'reward interpolation reaches actual event')
  local slot=D.test.data().slots[1];slot.voice.pending=nil;slot.voice.phase='build';slot.pacing.phase='peak';slot.pacing.phaseAt=now
  state.voice.patronAt=now-20;stage=31;at=t+2
 elseif stage==31 and t>at then
  local found=false;for _,line in ipairs(N.patronLines.peak)do if heard[#heard].text==line then found=true end end
  check(found,'actual scheduler peak caption uses patron')
  local slot=D.test.data().slots[1];slot.voice.pending=nil;slot.voice.phase='fade';slot.pacing.phase='relax';slot.pacing.untilTime=now+25
  state.voice.patronAt=now-20;stage=32;at=t+2
 elseif stage==32 and t>at then
  local found=false;for _,line in ipairs(N.patronLines.relax)do if heard[#heard].text==line then found=true end end
  check(found,'actual scheduler lull caption uses patron')
  D.test.retreat(p);stage=4;at=t+2
 elseif stage==4 and t>at then p:sendEvent('Patron_Report',{});stage=5;at=t+1
 elseif stage==5 and t>at then
  check(not report.visible and not report.message,'portal clears old floor caption')
  before=#heard;D.test.resume(p);stage=6;at=t+4
 elseif stage==6 and t>at then
  check(#heard==before,'resume does not repeat descent announcement')
  stage=7;types.Player.sendMenuEvent(p,'AshenLoot_TestSave')
 elseif stage==7 and loaded and t>at then
  check(#heard==before,'save/load does not replay floor announcement')
  D.test.data().depth=2;D.test.descend(p);stage=8;at=t+9
 elseif stage==8 and t>at then
  local slot=D.test.data().slots[3];check(slot.boss and not slot.voice.seen.guardian,'remote guardian generation does not announce engagement')
  local pos=layouts[3].exit;p:teleport(slot.cell,util.vector3(pos[1]-900,pos[2],8),{onGround=true})
  state.voice.patronAt=now-20;stage=9;at=t+3
 elseif stage==9 and t>at then
  local slot=D.test.data().slots[3];check(slot.voice.seen.guardian,'nearby guardian triggers patron cue')
  check(heard[#heard].speaker=='Fa-Nuit-Hen' and heard[#heard].text:lower():find('guardian',1,true)or heard[#heard].text:find('keeper',1,true),'actual guardian introduction')
  before=#heard;stage=10;at=t+4
 elseif stage==10 and t>at then
  check(#heard==before,'guardian approach cue does not repeat each update')
  local boss=D.test.data().slots[3].boss;boss:addScript('scripts/ashenloot_test/enemy_actor.lua');boss:sendEvent('EnemyTest_Health',0)
  state.voice.patronAt=now-20;stage=11;at=t+10
 elseif stage==11 and t>at then
  local slot=D.test.data().slots[3]
  check(slot.bossDefeated and slot.voice.seen.victory,'guardian victory queued once by actual death')
  local victoryCount=0
  for _,e in ipairs(heard)do for _,line in ipairs(N.patronLines.guardianVictory)do if e.text==line then victoryCount=victoryCount+1 end end end
  check(victoryCount==1,'actual guardian victory caption emitted exactly once')
  storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',0)
  before=#heard;N.offerDungeon(slot,nil,'peak',{},now,1);stage=12;at=t+3
 elseif stage==12 and t>at then
  check(#heard==before and not D.test.data().slots[3].voice.pending,'mute drops pending captions')
  p:teleport('',util.vector3(-7500,-68000,500),{onGround=true});stage=13;at=t+3
 elseif stage==13 and t>at then
  storage.globalSection(C.groupKey('directorVoiceFrequency')):set('directorVoiceFrequency',100)
  state.voice.lastAt=now-100;check(N.emitChance(state,C,p,now,'boss',{enemy='World Challenger'},100),'world event resumes outside dungeon')
  stage=14;at=t+1
 elseif stage==14 and t>at then
  check(heard[#heard].speaker=='Dagoth Ur','actual world voice restored after leaving')
  print('[PATRON] ALL PASS contextual pools, actual HUD/events, reward, guardian, mute, portal and save/load');core.quit();stage=99
 end
 if t>130 and stage~=99 then error('patron timeout stage '..stage)end
end
return {engineHandlers={onUpdate=function(dt)local ok,e=pcall(run,dt);if not ok then print('[PATRON] FAIL '..tostring(e));core.quit()end end,
 onSave=function()return{t=t,stage=stage,before=before,heard=heard}end,
 onLoad=function(v)if v then t=v.t;stage=v.stage;before=v.before;heard=v.heard;loaded=true;at=t+4 end end},eventHandlers={
 Patron_Heard=function(e)heard[#heard+1]=e;print('[PATRON EVENT] '..e.speaker..': '..e.text)end,
 Patron_Report=function(e)report=e end}}
