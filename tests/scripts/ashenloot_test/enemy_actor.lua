local core,self,types,I=require('openmw.core'),require('openmw.self'),require('openmw.types'),require('openmw.interfaces')
return {eventHandlers={EnemyTest_Health=function(f)local hp=types.Actor.stats.dynamic.health(self);hp.current=hp.base*f end,
 EnemyTest_Inspect=function()local combat=false;I.AI.forEachPackage(function(p)if p.type=='Combat' then combat=true end end);core.sendGlobalEvent('EnemyTest_Report',{id=self.id,fight=types.Actor.stats.ai.fight(self).base,flee=types.Actor.stats.ai.flee(self).base,combat=combat})end}}
