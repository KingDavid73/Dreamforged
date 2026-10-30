local R=require('scripts.ashenloot.rules')
local types=require('openmw.types')
return function(D,check)
 local S=D.test.selection
 local function average(theme,depth,optional)
  local total,mods,count,random=0,0,0,R.rng('depth-sample:'..theme..':'..depth)
  local selected={}
  for n=1,1024 do
   local id,e=D.test.selectEnemy(theme,false,random,depth,optional)
   assert(e.theme==theme,'theme mismatch');total=total+e.level
   if e.optional then mods=mods+1 else assert(id:find('df_delve_enemy_',1,true)==1,'bad native fallback')end
   selected[id]=true;count=count+1
  end
  return total/count,mods,selected
 end
 for theme=1,4 do
  local early=average(theme,1,false);local later=average(theme,25,false);local deep=average(theme,121,false)
  check(later>early and deep>=later,'native archetype strength increases and does not reset theme '..theme)
  local firstDepth=(theme-1)*3+1;local first=average(theme,firstDepth,false);local repeatCycle=average(theme,firstDepth+12,false)
  check(repeatCycle>first,'palette repeat advances archetypes theme '..theme)
  print('[ENEMY DEPTH] native theme '..theme..' mean level depth1='..early..' depth25='..later..' depth121='..deep)
  for _,depth in ipairs({1,13,25,49,97,121})do
   local a,b=R.rng('repeat:'..depth),R.rng('repeat:'..depth)
   for n=1,100 do assert(D.test.selectEnemy(theme,false,a,depth)==D.test.selectEnemy(theme,false,b,depth),'nondeterministic selection')end
   local _,mods=average(theme,depth,true);check(mods<=358,'optional content bounded below 35 percent theme '..theme..' depth '..depth)
  end
 end
 local totalOptional,selectedOptional=0,0
 for theme,pool in ipairs(S.catalog())do
  totalOptional=totalOptional+#pool.optional
  for _,e in ipairs(pool.optional)do
   local rec=types.Creature.records[e.id];assert(not rec.mwscript and not rec.isEssential and rec.canWalk,'unsafe optional candidate')
  end
  for _,depth in ipairs({1,7,13,25,49,97})do
   local _,mods,selected=average(theme,depth,true);selectedOptional=selectedOptional+mods
   for id in pairs(selected)do if S.describe(id).optional then print('[ENEMY DEPTH] optional selected '..id..' depth '..depth)end end
  end
 end
 check(totalOptional==0 or selectedOptional>0,'eligible optional creatures can actually be selected')
 print('[ENEMY DEPTH] optional catalog='..totalOptional..' optional sampled='..selectedOptional)
 local rec={id='mod_test_wolf',name='Wolf',model='wolf.nif',type=types.Creature.TYPE.Creatures,canWalk=true,isRespawning=true,combatSkill=30,attack={1,6,1,6,1,6},soulValue=4}
 check(S.classify(rec,true)==1,'ordinary listed mod wolf eligible without a dependency')
 for _,id in ipairs({'mod_quest_wolf','mod_pack_guar','mod_pet_wolf','mod_summon_wolf','mod_dead_wolf'})do local old=rec.id;rec.id=id;check(S.classify(rec,true)==nil,'special actor rejected '..id);rec.id=old end
 rec.mwscript='child_spawner';check(S.classify(rec,true)==nil,'scripted optional actor rejected');rec.mwscript=nil
 rec.isEssential=true;check(S.classify(rec,true)==nil,'essential optional actor rejected');rec.isEssential=false
 rec.servicesOffered={Travel=true};check(S.classify(rec,true)==nil,'service actor rejected');rec.servicesOffered=nil
 rec.isRespawning=false;check(S.classify(rec,false)==nil,'unplaced one-off rejected')
 check(S.classify(rec,true)==1,'ordinary leveled-list mod creature admitted')
 check(S.target(1,false)==1 and S.target(13,false)==10 and S.target(121,false)==91,'absolute-depth selection target is independent of player level')
 print('[ENEMY DEPTH] SAMPLES PASS')
end
