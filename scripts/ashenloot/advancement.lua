-- Pure progression definitions shared by player and global scripts.
local M={}
M.skills={
    armorer='combat',athletics='combat',axe='combat',block='combat',bluntweapon='combat',heavyarmor='combat',
    longblade='combat',mediumarmor='combat',spear='combat',
    alchemy='magic',alteration='magic',conjuration='magic',destruction='magic',enchant='magic',illusion='magic',
    mysticism='magic',restoration='magic',unarmored='magic',
    acrobatics='stealth',lightarmor='stealth',marksman='stealth',mercantile='stealth',security='stealth',
    shortblade='stealth',sneak='stealth',speechcraft='stealth',handtohand='stealth',
}
M.attributes={combat='endurance',magic='willpower',stealth='agility'}
M.masteries={
    armorer={'fortifyattribute','endurance',5},athletics={'fortifyattribute','speed',5},axe={'fortifyattribute','strength',5},
    block={'sanctuary',nil,5},bluntweapon={'fortifyattack',nil,5},heavyarmor={'shield',nil,8},
    longblade={'fortifyattack',nil,5},mediumarmor={'sanctuary',nil,5},spear={'fortifyattribute','agility',5},
    alchemy={'resistpoison',nil,15},alteration={'shield',nil,8},conjuration={'fortifymagicka',nil,20},
    destruction={'spellabsorption',nil,8},enchant={'fortifymagicka',nil,20},illusion={'chameleon',nil,8},
    mysticism={'resistmagicka',nil,10},restoration={'fortifyhealth',nil,15},unarmored={'sanctuary',nil,8},
    acrobatics={'fortifyattribute','speed',5},lightarmor={'sanctuary',nil,6},marksman={'fortifyattack',nil,5},
    mercantile={'fortifyattribute','personality',5},security={'fortifyattribute','luck',5},shortblade={'fortifyattack',nil,5},
    sneak={'chameleon',nil,8},speechcraft={'fortifyattribute','personality',5},handtohand={'fortifyattribute','strength',5},
}
M.passiveLevels={5,15,20,30,35,45}
M.activeLevels={10,25,40,50}
M.actives={
 combat={
  [10]={id='second_wind',name='Second Wind',cost={fatigue=15},cooldown=30,effects={{'restorehealth',12,5},{'restorefatigue',8,5}}},
  [25]={id='war_cry',name='War Cry',cost={fatigue=20},charges=3,recharge=7200,gameTime=true,effects={{'fortifyattack',12,20},{'fortifyattribute',10,20,'strength'}}},
  [40]={id='blood_rush',name='Blood Rush',cost={healthPercent=0.08,fatigue=15},cooldown=45,effects={{'fortifyattribute',20,18,'strength'},{'fortifyattribute',15,18,'speed'}}},
  [50]={id='unstoppable',name='Unstoppable',cost={fatigue=30},cooldown=90,effects={{'shield',30,25},{'sanctuary',15,25},{'resistparalysis',100,25}}},
 },
 magic={
  [10]={id='meditation',name='Meditation',cost={fatigue=10},cooldown=45,effects={{'restoremagicka',8,6}}},
  [25]={id='arcane_surge',name='Arcane Surge',cost={magickaPercent=0.18},charges=3,recharge=7200,gameTime=true,effects={{'fortifymagicka',35,25},{'spellabsorption',15,25}}},
  [40]={id='overchannel',name='Overchannel',cost={healthPercent=0.06,magickaPercent=0.20},cooldown=60,effects={{'fortifyattribute',20,20,'willpower'},{'reflect',15,20}}},
  [50]={id='aetherial_mastery',name='Aetherial Mastery',cost={magickaPercent=0.30},cooldown=120,effects={{'spellabsorption',30,30},{'restoremagicka',10,10},{'resistmagicka',20,30}}},
 },
 stealth={
  [10]={id='shadowstep',name='Shadowstep',cost={fatigue=15},cooldown=30,effects={{'chameleon',35,8},{'fortifyattribute',20,8,'speed'}}},
  [25]={id='hunters_focus',name="Hunter's Focus",cost={fatigue=20},charges=3,recharge=7200,gameTime=true,effects={{'fortifyattack',15,25},{'fortifyattribute',12,25,'agility'}}},
  [40]={id='vanish',name='Vanish',cost={fatiguePercent=0.22},cooldown=60,effects={{'invisibility',1,12},{'sanctuary',20,12}}},
  [50]={id='hidden_master',name='Master of the Hidden Path',cost={fatigue=30},cooldown=120,effects={{'chameleon',50,25},{'fortifyattribute',25,25,'speed'},{'fortifyattack',15,25}}},
 },
}
M.skillActives={
 armorer={level=75,id='field_fortification',name='Field Fortification',cost={fatigue=18},cooldown=45,effects={{'shield',20,30}}},
 athletics={level=75,id='second_breath',name='Second Breath',cost={health=3},cooldown=30,effects={{'restorefatigue',12,6},{'fortifyattribute',12,15,'speed'}}},
 axe={level=75,id='hewers_fury',name="Hewer's Fury",cost={fatigue=22},cooldown=35,effects={{'fortifyattribute',18,18,'strength'},{'fortifyattack',10,18}}},
 block={level=75,id='immovable_guard',name='Immovable Guard',cost={fatigue=18},cooldown=40,effects={{'shield',30,15},{'sanctuary',15,15}}},
 bluntweapon={level=75,id='earthshaker',name='Earthshaker',cost={fatigue=25},cooldown=40,effects={{'fortifyattack',16,15},{'fortifyattribute',15,15,'strength'}}},
 heavyarmor={level=75,id='iron_bastion',name='Iron Bastion',cost={fatigue=20},cooldown=55,effects={{'shield',35,20},{'resistparalysis',100,20}}},
 longblade={level=75,id='swordsaint_focus',name='Sword-Saint Focus',cost={fatigue=20},cooldown=35,effects={{'fortifyattack',18,18},{'sanctuary',10,18}}},
 mediumarmor={level=75,id='bonemold_balance',name='Bonemold Balance',cost={fatigue=16},cooldown=40,effects={{'shield',20,25},{'fortifyattribute',10,25,'agility'}}},
 spear={level=75,id='veloths_reach',name="Veloth's Reach",cost={fatigue=20},cooldown=35,effects={{'fortifyattack',14,20},{'fortifyattribute',15,20,'agility'}}},
 alchemy={level=75,id='panacea',name='Panacea',cost={magicka=5},charges=2,recharge=10800,gameTime=true,effects={{'curepoison',1,1},{'restorehealth',6,8},{'restorefatigue',8,8}}},
 alteration={level=75,id='unbound_step',name='Unbound Step',cost={magicka=18},cooldown=45,effects={{'levitate',18,15},{'shield',15,15}}},
 conjuration={level=75,id='blood_covenant',name='Blood Covenant',cost={healthPercent=0.12},cooldown=90,effects={{'summonancestralghost',1,35},{'fortifymagicka',25,35}}},
 destruction={level=75,id='triune_ruin',name='Triune Ruin',cost={magickaPercent=0.22},cooldown=35,target=true,effects={{'firedamage',6,3},{'frostdamage',6,3},{'shockdamage',8,2}}},
 enchant={level=75,id='aether_tap',name='Aether Tap',cost={fatigue=10},cooldown=50,effects={{'restoremagicka',8,8},{'spellabsorption',15,20}}},
 illusion={level=75,id='walk_unseen',name='Walk Unseen',cost={magicka=20},cooldown=55,effects={{'invisibility',1,15},{'chameleon',25,25}}},
 mysticism={level=75,id='grave_hunger',name='Grave Hunger',cost={magicka=12,healthPercent=0.04},cooldown=25,target=true,effects={{'absorbhealth',8,4}}},
 restoration={level=75,id='mercy_of_stendarr',name='Mercy of Stendarr',cost={magickaPercent=0.18},cooldown=40,effects={{'restorehealth',10,8},{'restorefatigue',10,8}}},
 unarmored={level=75,id='empty_robe',name='The Empty Robe',cost={magicka=12,fatigue=12},cooldown=40,effects={{'sanctuary',25,18},{'shield',18,18}}},
 acrobatics={level=75,id='pilgrims_leap',name="Pilgrim's Leap",cost={fatigue=15},cooldown=25,effects={{'slowfall',25,15},{'fortifyattribute',20,12,'speed'}}},
 lightarmor={level=75,id='glass_shadow',name='Glass Shadow',cost={fatigue=18},cooldown=35,effects={{'sanctuary',20,18},{'chameleon',15,18}}},
 marksman={level=75,id='eyes_of_azura',name='Eyes of Azura',cost={fatigue=20},cooldown=35,effects={{'fortifyattack',20,18},{'fortifyattribute',18,18,'agility'}}},
 mercantile={level=75,id='golden_tongue',name='Golden Tongue',cost={fatigue=8},charges=3,recharge=3600,gameTime=true,effects={{'fortifyattribute',25,45,'personality'},{'fortifyskill',15,45,nil,'mercantile'}}},
 security={level=75,id='no_lock_unseen',name='No Lock Unseen',cost={fatigue=12},cooldown=30,effects={{'detectkey',50,20},{'fortifyskill',20,20,nil,'security'}}},
 shortblade={level=75,id='serpents_kiss',name="Serpent's Kiss",cost={fatigue=18},cooldown=25,target=true,effects={{'poison',7,5},{'burden',12,5}}},
 sneak={level=75,id='moth_step',name='Moth-Step',cost={fatigue=20},cooldown=45,effects={{'invisibility',1,12},{'fortifyskill',20,20,nil,'sneak'}}},
 speechcraft={level=75,id='voice_of_command',name='Voice of Command',cost={fatigue=10},cooldown=60,target=true,effects={{'commandhumanoid',100,12}}},
 handtohand={level=75,id='five_fingered_calm',name='Five-Fingered Calm',cost={fatigue=18},cooldown=25,target=true,effects={{'damagefatigue',15,4},{'burden',15,4}}},
}
function M.specialty(class,specialization)
    class=tostring(class or ''):lower();specialization=tostring(specialization or ''):lower()
    if class:find('warmage',1,true) or class:find('conjurer',1,true) then return 'magic' end
    if class:find('archer',1,true) or class:find('rogue',1,true) then return 'stealth' end
    if class:find('warrior',1,true) then return 'combat' end
    return (specialization=='combat' or specialization=='magic' or specialization=='stealth') and specialization or 'combat'
end
return M
